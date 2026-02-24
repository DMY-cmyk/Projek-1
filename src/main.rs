use clap::{Parser, Subcommand};

mod sec_api;
mod pipeline;

#[derive(Parser)]
#[command(name = "projek-1", version, about = "Apple fundamentals analysis toolkit")]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Fetch and cache SEC API JSON (companyfacts + submissions)
    FetchSec {
        /// CIK with or without leading zeros
        #[arg(long)]
        cik: String,
        /// Output directory for cached JSON and request_log.csv
        #[arg(long, default_value = "research/sec")]
        out_dir: String,
        /// SEC-required User-Agent string (Name email@domain.com)
        #[arg(long)]
        user_agent: String,
        /// Re-download even if cached files exist
        #[arg(long, default_value_t = false)]
        refresh: bool,
        /// Maximum requests per second (0 disables throttling)
        #[arg(long, default_value_t = 10)]
        max_per_sec: u32,
    },
    /// Run the full analysis pipeline (SEC fetch -> metrics -> valuation -> report -> charts)
    RunPipeline {
        /// CIK with or without leading zeros
        #[arg(long)]
        cik: String,
        /// Output directory for cached JSON and request_log.csv
        #[arg(long, default_value = "research/sec")]
        out_dir: String,
        /// SEC-required User-Agent string (Name email@domain.com)
        #[arg(long)]
        user_agent: String,
        /// Re-download even if cached files exist
        #[arg(long, default_value_t = false)]
        refresh: bool,
        /// Maximum requests per second (0 disables throttling)
        #[arg(long, default_value_t = 10)]
        max_per_sec: u32,
        /// Market price for valuation snapshot
        #[arg(long)]
        price: f64,
        /// Market price as-of date (YYYY-MM-DD)
        #[arg(long)]
        as_of_date: String,
    },
}

fn main() -> anyhow::Result<()> {
    let cli = Cli::parse();

    match cli.command {
        Commands::FetchSec {
            cik,
            out_dir,
            user_agent,
            refresh,
            max_per_sec,
        } => sec_api::fetch_sec(sec_api::FetchOptions {
            cik,
            out_dir: out_dir.into(),
            user_agent,
            refresh,
            max_per_sec,
        })?,
        Commands::RunPipeline {
            cik,
            out_dir,
            user_agent,
            refresh,
            max_per_sec,
            price,
            as_of_date,
        } => pipeline::run_pipeline(pipeline::PipelineOptions {
            cik,
            out_dir: out_dir.into(),
            user_agent,
            refresh,
            max_per_sec,
            price,
            as_of_date,
        })?,
    }

    Ok(())
}
