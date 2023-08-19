#[macro_use]
mod macros;

pub mod token;

#[cfg(test)]
mod lexer_test;

use std::borrow::Cow;
use std::mem::MaybeUninit;

use token::*;

#[derive(Debug)]
pub struct Lexer<'s> {
    source: &'s [u8],
    idx: usize,
}

impl<'s> Lexer<'s> {
    pub fn new(source: &'s str) -> Self {
        Self {
            source: source.as_bytes(),
            idx: 0,
        }
    }

    pub fn new_with_bytes(source: &'s [u8]) -> Self {
        Self { source, idx: 0 }
    }

    #[inline]
    fn peek(&self) -> Option<u8> {
        self.source.get(self.idx + 1).copied()
    }

    /// This function does not check the boundary, so it may panic.
    #[inline]
    fn get_byte(&self) -> u8 {
        self.source[self.idx]
    }

    pub fn next_token(&mut self) -> Option<Token<'s>> {
        #[repr(u8)]
        enum State {
            Start,
            Whitespace,
            Comment,
            Integer,
            Float,
            Variable,
            StringLiteral,
            Backslash,
            Minus,
            End,
        }

        let mut state = State::Start;
        let mut start_idx: usize = 0;
        let mut string_literal: Option<Vec<u8>> = None;
        let mut token = MaybeUninit::<Token>::uninit();

        loop {
            if self.idx < self.source.len() {
                match state {
                    State::Start => {
                        start_idx = self.idx;

                        match self.get_byte() {
                            // symbols
                            b'.' => lex_symbol!(self: state, token  | Period       ),
                            b',' => lex_symbol!(self: state, token  | Comma        ),
                            b'+' => lex_symbol!(self: state, token  | Plus         ),
                            b'*' => lex_symbol!(self: state, token  | Star         ),
                            b'/' => lex_symbol!(self: state, token  | Slash        ),
                            b'\\' => lex_symbol!(self: state, token | Backslash    ),
                            b'|' => lex_symbol!(self: state, token  | Vert         ),
                            b'!' => lex_symbol!(self: state, token  | Bang         ),
                            b'=' => lex_symbol!(self: state, token  | Equal        ),
                            b'<' => lex_symbol!(self: state, token  | Less         ),
                            b'>' => lex_symbol!(self: state, token  | Great        ),
                            b'@' => lex_symbol!(self: state, token  | At           ),
                            b'^' => lex_symbol!(self: state, token  | Hat          ),
                            b'_' => lex_symbol!(self: state, token  | Underscore   ),
                            b'#' => lex_symbol!(self: state, token  | Sharp        ),
                            b'%' => lex_symbol!(self: state, token  | Percent      ),
                            b'&' => lex_symbol!(self: state, token  | Ampersand    ),
                            b'$' => lex_symbol!(self: state, token  | Dollar       ),
                            b'~' => lex_symbol!(self: state, token  | Tilde        ),
                            b':' => lex_symbol!(self: state, token  | Colon        ),
                            b';' => lex_symbol!(self: state, token  | Semicolon    ),
                            b'\'' => lex_symbol!(self: state, token | Quote        ),
                            b'(' => lex_symbol!(self: state, token  | LeftParen    ),
                            b')' => lex_symbol!(self: state, token  | RightParen   ),
                            b'{' => lex_symbol!(self: state, token  | LeftBracket  ),
                            b'}' => lex_symbol!(self: state, token  | RightBracket ),
                            b'[' => lex_symbol!(self: state, token  | LeftSquare   ),
                            b']' => lex_symbol!(self: state, token  | RightSquare  ),

                            b'-' => {
                                state = State::Minus;
                                continue;
                            }
                            b'"' => {
                                self.idx += 1;
                                string_literal = Some(Vec::with_capacity(25));
                                state = State::StringLiteral;
                                continue;
                            }
                            b'`' => {
                                self.idx += 1;
                                state = State::Comment;
                                continue;
                            }

                            // keywords
                            b'A' => lex_symbol!(self: state, token | AssignPop  ),
                            b'C' => lex_symbol!(self: state, token | Assign     ),
                            b'D' => lex_symbol!(self: state, token | Decrement  ),
                            b'E' => lex_symbol!(self: state, token | Exponent   ),
                            b'F' => lex_symbol!(self: state, token | FloatType  ),
                            b'H' => lex_symbol!(self: state, token | Hashmap    ),
                            b'I' => lex_symbol!(self: state, token | IntegerType),
                            b'M' => lex_symbol!(self: state, token | Map        ),
                            b'P' => lex_symbol!(self: state, token | Print      ),
                            b'U' => lex_symbol!(self: state, token | Increment  ),

                            b'L' => match self.peek() {
                                Some(b'K') => {
                                    tokenize!(token := TokenType::LoopKey,
                                        &self.source[self.idx..self.idx + 2]);
                                    self.idx += 2;
                                    state = State::End;
                                }
                                Some(b'V') => {
                                    tokenize!(token := TokenType::LoopValue,
                                        &self.source[self.idx..self.idx + 2]);
                                    self.idx += 2;
                                    state = State::End;
                                }
                                _ => lex_symbol!(self: state, token | Loop),
                            },

                            // integers, floats, and variables
                            byte if byte.is_ascii_whitespace() => {
                                state = State::Whitespace;
                                continue;
                            }
                            byte if byte.is_ascii_digit() => {
                                state = State::Integer;
                                continue;
                            }
                            byte if byte.is_ascii_lowercase() => {
                                state = State::Variable;
                                continue;
                            }
                            _ => {
                                tokenize!(token := TokenType::Illegal,
                                        &self.source[self.idx..self.idx + 1]);
                                self.idx += 1;
                                state = State::End;
                            }
                        }
                    }
                    State::Whitespace => {
                        if self.get_byte().is_ascii_whitespace() {
                            self.idx += 1;
                            continue;
                        }
                        state = State::Start;
                    }
                    State::Comment => {
                        if self.get_byte() == b'\n' || self.get_byte() == b'`' {
                            self.idx += 1;
                            state = State::Start;
                        } else {
                            self.idx += 1;
                        }
                    }
                    State::Minus => {
                        if self.peek() == Some(b'.') {
                            self.idx += 2;
                            state = State::Float;
                            continue;
                        }
                        if self
                            .peek()
                            .map(|byte| byte.is_ascii_digit())
                            .unwrap_or_default()
                        {
                            self.idx += 1;
                            state = State::Integer;
                            continue;
                        }
                        lex_symbol!(self: state, token | Minus);
                    }
                    State::Integer => {
                        let byte = self.get_byte();

                        if byte == b'.' {
                            self.idx += 1;
                            state = State::Float;
                            continue;
                        }
                        if !byte.is_ascii_digit() {
                            tokenize!(token := TokenType::Integer, &self.source[start_idx..self.idx]);
                            state = State::End;
                            continue;
                        }

                        self.idx += 1;
                    }
                    State::Float => {
                        if !self.get_byte().is_ascii_digit() {
                            tokenize!(token := TokenType::Float, &self.source[start_idx..self.idx]);
                            state = State::End;
                            continue;
                        }

                        self.idx += 1;
                    }
                    State::Variable => {
                        if !self.get_byte().is_ascii_lowercase() {
                            tokenize!(token := TokenType::Variable, &self.source[start_idx..self.idx]);
                            state = State::End;
                            continue;
                        }

                        self.idx += 1;
                    }
                    State::StringLiteral => {
                        if self.get_byte() == b'"' {
                            if let Some(lit) = string_literal {
                                token.write(match String::from_utf8(lit) {
                                    Ok(lit) => Token {
                                        toktype: TokenType::String,
                                        literal: Cow::Owned(lit),
                                    },
                                    Err(_) => Token {
                                        toktype: TokenType::Illegal,
                                        literal: String::from_utf8_lossy(
                                            &self.source[start_idx..self.idx + 1],
                                        ),
                                    },
                                });
                                string_literal = None;
                            } else {
                                token.write(Token {
                                    toktype: TokenType::String,
                                    literal: Cow::Owned(String::new()),
                                });
                            }
                            self.idx += 1;
                            state = State::End;
                            continue;
                        }
                        if self.get_byte() == b'\\' {
                            self.idx += 1;
                            state = State::Backslash;
                            continue;
                        }

                        string_literal
                            .as_mut()
                            .map(|lit| lit.push(self.get_byte()))
                            .unwrap_or_default();
                        self.idx += 1;
                    }
                    State::Backslash => {
                        match self.get_byte() {
                            b'n' => string_literal
                                .as_mut()
                                .map(|lit| lit.push(b'\n'))
                                .unwrap_or_default(),
                            b't' => string_literal
                                .as_mut()
                                .map(|lit| lit.push(b'\t'))
                                .unwrap_or_default(),
                            b'\\' => string_literal
                                .as_mut()
                                .map(|lit| lit.push(b'\\'))
                                .unwrap_or_default(),
                            b'"' => string_literal
                                .as_mut()
                                .map(|lit| lit.push(b'"'))
                                .unwrap_or_default(),
                            _ => {
                                tokenize!(token := TokenType::Illegal,
                                &self.source[self.idx - 1..self.idx]);
                                self.idx += 1;
                                state = State::End;
                                continue;
                            }
                        }
                        state = State::StringLiteral;
                        self.idx += 1;
                    }
                    State::End => {
                        // SAFETY: In the End state, token is initialized.
                        break Some(unsafe { token.assume_init() });
                    }
                }
            } else {
                break match state {
                    State::Start | State::Whitespace | State::Comment => None,
                    State::Integer => {
                        tokenize!(token := TokenType::Integer, &self.source[start_idx..self.idx]);
                        // SAFETY: Token is initialized as in above
                        Some(unsafe { token.assume_init() })
                    }
                    State::Float => {
                        tokenize!(token := TokenType::Float, &self.source[start_idx..self.idx]);
                        // SAFETY: Token is initialized as in above
                        Some(unsafe { token.assume_init() })
                    }
                    State::Variable => {
                        tokenize!(token := TokenType::Variable, &self.source[start_idx..self.idx]);
                        // SAFETY: Token is initialized as in above
                        Some(unsafe { token.assume_init() })
                    }
                    State::Minus => {
                        tokenize!(token := TokenType::Minus, &self.source[start_idx..self.idx]);
                        // SAFETY: Token is initialized as in above
                        Some(unsafe { token.assume_init() })
                    }
                    State::StringLiteral => {
                        tokenize!(token := TokenType::Illegal, &self.source[start_idx..self.idx]);
                        // SAFETY: Token is initialized as in above
                        Some(unsafe { token.assume_init() })
                    }
                    State::Backslash => {
                        tokenize!(token := TokenType::Illegal,
                                  &self.source[self.idx.saturating_sub(1)..self.idx]);
                        // SAFETY: Token is initialized as in above
                        Some(unsafe { token.assume_init() })
                    }
                    State::End => {
                        // SAFETY: In the End state, token is initialized.
                        Some(unsafe { token.assume_init() })
                    }
                };
            }
        }
    }
}

impl<'s> Iterator for Lexer<'s> {
    type Item = Token<'s>;
    fn next(&mut self) -> Option<Self::Item> {
        self.next_token()
    }
}
