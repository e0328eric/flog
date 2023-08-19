macro_rules! stmt {
    ("assign": $var_name: expr, $is_pop: expr) => {
        Stmt::Assign {
            var_name: $var_name,
            is_pop: $is_pop,
        }
    };
    ("if": $conditional: expr, $true_stmt: expr, $false_stmt: expr) => {
        Stmt::If {
            conditional: Box::new($conditional),
            true_stmt: Some(Box::new($true_stmt)),
            false_stmt: Some(Box::new($false_stmt)),
        }
    };
    ("ifT": $conditional: expr, $true_stmt: expr) => {
        Stmt::If {
            conditional: Box::new($conditional),
            true_stmt: Some(Box::new($true_stmt)),
            false_stmt: None,
        }
    };
    ("ifF": $conditional: expr, $false_stmt: expr) => {
        Stmt::If {
            conditional: Box::new($conditional),
            true_stmt: None,
            false_stmt: Some(Box::new($false_stmt)),
        }
    };
    ("loop": $conditional: expr, $loop_stmt: expr) => {
        Stmt::Loop {
            conditional: Box::new($conditional),
            loop_stmt: Box::new($loop_stmt),
        }
    };
    ("macro": $macro_name: expr, $impl: expr) => {
        Stmt::MacroDef {
            macro_name: $macro_name,
            implementation: Box::new($impl),
        }
    };
    ("print") => {
        Stmt::Print { attribute: None }
    };
    ("print_attr": $attr: expr) => {
        Stmt::Print {
            attribute: Some($attr),
        }
    };
    ("scope": $inner: expr) => {
        Stmt::Scope($inner)
    };
}

macro_rules! expr {
    ("int": $integer: expr) => {
        Expr::Hashable(HashableExpr::Integer(BigInt::from($integer)))
    };
    ("string": $string: expr) => {
        Expr::Hashable(HashableExpr::String(String::from($string)))
    };
}
