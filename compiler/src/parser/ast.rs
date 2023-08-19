use std::collections::HashMap;

use crate::lexer::token::TokenType;

#[derive(Debug, Clone)]
pub enum Stmt {
    EmptyStmt,
    Assignment {
        var_name: String,
        is_pop: bool,
    },
    If {
        conditional: Box<Self>,
        true_stmt: Option<Box<Self>>,
        false_stmt: Option<Box<Self>>,
    },
    Loop {
        conditional: Box<Self>,
        loop_stmt: Box<Self>,
    },
    MacroDef {
        macro_name: String,
        implementation: Box<Self>,
    },
    Print {
        attribute: Option<String>,
    },
    Scope(Vec<Self>),
    Symbol(TokenType),
    ExprStmt(Expr),
}

#[derive(Debug, Clone)]
pub enum Expr {
    Hashable(HashableExpr),
    Variable(String),
    Float(f64),
    Array(Vec<Self>),
    HashMap(HashMap<HashableExpr, Self>),
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum HashableExpr {
    Integer(num_bigint::BigInt),
    String(String),
}

impl From<HashableExpr> for Expr {
    fn from(value: HashableExpr) -> Self {
        Self::Hashable(value)
    }
}
