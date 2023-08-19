use std::borrow::Cow;

#[repr(u8)]
#[derive(Debug, Clone, PartialEq)]
pub enum TokenType {
    // literals
    Integer,
    Float,
    String,
    Variable,

    // symbols
    Period,      // .
    Comma,       // ,
    Plus,        // +
    Minus,       // -
    Star,        // *
    Slash,       // /
    Backslash,   // \
    Vert,        // |
    Bang,        // !
    Equal,       // =
    Less,        // <
    Great,       // >
    At,          // @
    Hat,         // ^
    Underscore,  // _
    Sharp,       // #
    Percent,     // %
    Ampersand,   // &
    Dollar,      // $
    Tilde,       // ~
    Colon,       // :
    Semicolon,   // ;
    Quote,       // '
    Doublequote, // "

    // brackets
    LeftParen,    // (
    RightParen,   // )
    LeftBracket,  // {
    RightBracket, // }
    LeftSquare,   // [
    RightSquare,  // ]

    // keywords
    AssignPop,   // the A character
    Assign,      // the C character
    Decrement,   // the D character
    Exponent,    // the E character
    FloatType,   // the F character
    Hashmap,     // the H character
    IntegerType, // the I character
    Loop,        // the L character
    LoopKey,     // the LK character
    LoopValue,   // the LV character
    Map,         // the M character
    Print,       // the P character
    Increment,   // the U character

    Illegal = 0xFF,
}

#[derive(Debug, Clone)]
pub struct Token<'tok> {
    pub toktype: TokenType,
    pub literal: Cow<'tok, str>,
}
