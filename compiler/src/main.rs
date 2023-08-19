use flog_compiler::lexer::Lexer;

fn main() {
    let source = r#"(,,P:"{} bottles of beer {}\n";):a;99L{#0>}{##"on the wall"a"\nTake one down, pass it around"a_}"#;
    let lex = Lexer::new(source);
    for token in lex {
        println!("{token:?}");
    }
}
