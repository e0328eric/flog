use super::token::*;
use super::Lexer;

#[test]
fn lexing_symbols() {
    let program = "~!\nLLV@LK& &^$%";
    let expected_lst = [
        (TokenType::Tilde, "~"),
        (TokenType::Bang, "!"),
        (TokenType::Loop, "L"),
        (TokenType::LoopValue, "LV"),
        (TokenType::At, "@"),
        (TokenType::LoopKey, "LK"),
        (TokenType::Ampersand, "&"),
        (TokenType::Ampersand, "&"),
        (TokenType::Hat, "^"),
        (TokenType::Dollar, "$"),
        (TokenType::Percent, "%"),
    ];
    let mut lexer = Lexer::new(program);

    for (toktype, literal) in expected_lst {
        let token = lexer.next();
        assert!(token.is_some());

        let token = token.unwrap();
        assert_eq!(token.toktype, toktype);
        assert_eq!(token.literal, literal);
    }

    assert!(lexer.next().is_none());
}

#[test]
fn lexing_numbers() {
    let testing_list = [
        ("1234", TokenType::Integer),
        ("-401", TokenType::Integer),
        ("12.54", TokenType::Float),
        ("-123.54", TokenType::Float),
        ("-.54", TokenType::Float),
    ];

    for (source, toktype) in testing_list {
        let mut lexer = Lexer::new(source);
        let token = lexer.next();
        assert!(token.is_some());

        let token = token.unwrap();
        assert_eq!(token.toktype, toktype);
        assert_eq!(token.literal, source);
    }
}

#[test]
fn lexing_strings_correct() {
    let testing_list = [
        ("\"Hello, World!\"", "Hello, World!"),
        ("\"Hello,\\n World!\"", "Hello,\n World!"),
        ("\"ども、サメです。\"", "ども、サメです。"),
        ("\"ども、\\\\サメです。\"", "ども、\\サメです。"),
    ];

    for (source, expected) in testing_list {
        let mut lexer = Lexer::new(source);
        let token = lexer.next();
        assert!(token.is_some());

        let token = token.unwrap();
        assert_eq!(token.toktype, TokenType::String);
        assert_eq!(token.literal, expected);
    }
}

#[test]
fn lexing_strings_incorrect() {
    let testing_list = [
        ("\"Hello, World!", "\"Hello, World!"),
        ("\"Hello, \\World!", "\\"),
        ("\"ども、\\サメです。\"", "\\"),
    ];

    for (source, expected) in testing_list {
        let mut lexer = Lexer::new(source);
        let token = lexer.next();
        assert!(token.is_some());

        let token = token.unwrap();
        assert_eq!(token.toktype, TokenType::Illegal);
        assert_eq!(token.literal, expected);
    }
}

#[test]
fn lexing_simple_program() {
    let program = r#"(,,P:"{} bottles of beer {}\n";): foo `the variable name is foo`;
    99L{#0>}{##"on the wall"foo "\nTake one down, pass it around"fooD}`looping"#;
    let expected_lst = [
        (TokenType::LeftParen, "("),
        (TokenType::Comma, ","),
        (TokenType::Comma, ","),
        (TokenType::Print, "P"),
        (TokenType::Colon, ":"),
        (TokenType::String, "{} bottles of beer {}\n"),
        (TokenType::Semicolon, ";"),
        (TokenType::RightParen, ")"),
        (TokenType::Colon, ":"),
        (TokenType::Variable, "foo"),
        (TokenType::Semicolon, ";"),
        (TokenType::Integer, "99"),
        (TokenType::Loop, "L"),
        (TokenType::LeftBracket, "{"),
        (TokenType::Sharp, "#"),
        (TokenType::Integer, "0"),
        (TokenType::Great, ">"),
        (TokenType::RightBracket, "}"),
        (TokenType::LeftBracket, "{"),
        (TokenType::Sharp, "#"),
        (TokenType::Sharp, "#"),
        (TokenType::String, "on the wall"),
        (TokenType::Variable, "foo"),
        (TokenType::String, "\nTake one down, pass it around"),
        (TokenType::Variable, "foo"),
        (TokenType::Decrement, "D"),
        (TokenType::RightBracket, "}"),
    ];

    let mut lexer = Lexer::new(program);

    for (toktype, literal) in expected_lst {
        let token = lexer.next();
        println!("{token:?}");
        assert!(token.is_some());

        let token = token.unwrap();
        assert_eq!(token.toktype, toktype);
        assert_eq!(token.literal, literal);
    }

    assert!(lexer.next().is_none());
}
