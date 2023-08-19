use num_bigint::BigInt;

use super::ast::*;
use crate::lexer::token::TokenType;

#[test]
fn parse_simple_program() {
    let program = r#"(,,P:"{} bottles of beer {}\n";): foo `the variable name is foo`;
    99L{#0>}{##"on the wall"foo "\nTake one down, pass it around"fooD}`looping"#;

    let ast = vec![
        stmt!("macro": String::from("foo"),
            stmt!("scope":
                vec![
                    Stmt::Symbol(TokenType::Comma),
                    Stmt::Symbol(TokenType::Comma),
                    stmt!("print_attr": String::from("{} bottles of beer {}\n")),
                ]
            )
        ),
        Stmt::ExprStmt(expr!("int": 99)),
        stmt!("loop":
            stmt!("scope":
                vec![
                    Stmt::Symbol(TokenType::Sharp),
                    Stmt::ExprStmt(expr!("int": 0)),
                    Stmt::Symbol(TokenType::Great),
                ]
            ),
            stmt!("scope":
                vec![
                    Stmt::Symbol(TokenType::Sharp),
                    Stmt::Symbol(TokenType::Sharp),
                    Stmt::ExprStmt(expr!("string": String::from("on the wall"))),
                    Stmt::ExprStmt(Expr::Variable(String::from("foo"))),
                    Stmt::ExprStmt(expr!("string": String::from("\nTake one down, pass it around"))),
                    Stmt::ExprStmt(Expr::Variable(String::from("foo"))),
                    Stmt::Symbol(TokenType::Decrement),
                ]
            )
        ),
    ];
}
