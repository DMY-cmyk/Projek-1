use anyhow::{Context, Result};
use std::path::PathBuf;
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
    // Reserved for future direct Rust fetch orchestration; current flow delegates to PowerShell pipeline.
    let _ = (&opts.cik, &opts.out_dir, opts.max_per_sec);

    let mut refresh_args = vec![
        "-UserAgent".to_string(),
        opts.user_agent.clone(),
        "-Price".to_string(),
        format!("{:.4}", opts.price),
        "-AsOfDate".to_string(),
        opts.as_of_date.clone(),
    ];
    if opts.refresh {
        refresh_args.push("-ForceFresh".to_string());
    }
    run_ps(
        "scripts/refresh_all_report.ps1",
        &refresh_args.iter().map(String::as_str).collect::<Vec<_>>(),
    )?;
    run_ps("scripts/verify_outputs.ps1", &[])?;
    run_ps("scripts/build_export_bundle.ps1", &[])?;

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
