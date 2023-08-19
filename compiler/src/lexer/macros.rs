macro_rules! tokenize {
    ($token: ident := $toktype: expr, $literal: expr) => {
        $token.write(Token {
            toktype: $toktype,
            literal: String::from_utf8_lossy($literal),
        });
    };
}

macro_rules! lex_symbol {
    ($self: ident: $state: ident, $token: ident | $toktype: ident) => {
        {
            tokenize!($token := TokenType::$toktype,
                    &$self.source[$self.idx..$self.idx + 1]);
            $self.idx += 1;
            $state = State::End;
        }
    };
}
