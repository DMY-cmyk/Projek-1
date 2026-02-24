use crate::sec_api::{fetch_sec, FetchOptions};
use anyhow::{Context, Result};
use std::path::{Path, PathBuf};
use std::process::Command;

pub struct PipelineOptions {
    pub cik: String,
    pub out_dir: PathBuf,
    pub user_agent: String,
    pub refresh: bool,
    pub max_per_sec: u32,
    pub price: f64,
    pub as_of_date: String,
}

pub fn run_pipeline(opts: PipelineOptions) -> Result<()> {
    fetch_sec(FetchOptions {
        cik: opts.cik.clone(),
        out_dir: opts.out_dir.clone(),
        user_agent: opts.user_agent,
        refresh: opts.refresh,
        max_per_sec: opts.max_per_sec,
    })?;

    let cik = normalize_cik(&opts.cik)?;
    let companyfacts_path = opts
        .out_dir
        .join(format!("companyfacts_{cik}.json"));

    run_ps(
        "scripts/extract_companyfacts.ps1",
        &[
            "-CompanyFactsPath",
            companyfacts_path
                .to_str()
                .context("companyfacts path")?,
        ],
    )?;
    run_ps("scripts/compute_metrics.ps1", &[])?;
    run_ps("scripts/validate_financials.ps1", &[])?;
    run_ps(
        "scripts/compute_valuation.ps1",
        &[
            "-Price",
            &format!("{:.2}", opts.price),
            "-AsOfDate",
            &opts.as_of_date,
        ],
    )?;
    run_ps("scripts/build_report.ps1", &[])?;
    run_ps("scripts/build_charts.ps1", &[])?;

    Ok(())
}

fn run_ps(script: &str, args: &[&str]) -> Result<()> {
    let mut cmd = Command::new("powershell.exe");
    cmd.arg("-ExecutionPolicy")
        .arg("Bypass")
        .arg("-File")
        .arg(script);
    for arg in args {
        cmd.arg(arg);
    }

    let status = cmd.status().with_context(|| format!("run {script}"))?;
    if !status.success() {
        anyhow::bail!("{script} failed with status {status}");
    }
    Ok(())
}

fn normalize_cik(cik: &str) -> Result<String> {
    let trimmed = cik.trim().trim_start_matches("CIK");
    let digits: String = trimmed.chars().filter(|c| c.is_ascii_digit()).collect();
    if digits.is_empty() {
        anyhow::bail!("CIK is empty or invalid");
    }
    Ok(format!("{:0>10}", digits))
}
