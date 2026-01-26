fn main() {
    let args: Vec<String> = std::env::args().collect();
    println!("projek-1 starting with {} arg(s).", args.len().saturating_sub(1));
}
