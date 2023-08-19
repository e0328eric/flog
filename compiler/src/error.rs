use std::fmt::{self, Display};

// Parser Error marker
pub struct ParserError;
pub type ParserResult<T> = error_stack::Result<T, ParserError>;

impl Display for ParserError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str("Error occurs while parsing the flog")
    }
}
