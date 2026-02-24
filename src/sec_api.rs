use anyhow::{Context, Result};
use reqwest::blocking::Client;
use reqwest::header::{HeaderMap, HeaderValue, ACCEPT, ACCEPT_ENCODING, USER_AGENT};
use std::fs;
use std::io::Write;
use std::path::{Path, PathBuf};
use std::thread;
use std::time::Duration;
use time::format_description::well_known::Rfc3339;
use time::OffsetDateTime;

pub struct FetchOptions {
    pub cik: String,
    pub out_dir: PathBuf,
    pub user_agent: String,
    pub refresh: bool,
    pub max_per_sec: u32,
}

pub fn fetch_sec(opts: FetchOptions) -> Result<()> {
    fs::create_dir_all(&opts.out_dir)
        .with_context(|| format!("create output dir {}", opts.out_dir.display()))?;

    let mut headers = HeaderMap::new();
    headers.insert(
        USER_AGENT,
        HeaderValue::from_str(&opts.user_agent).context("invalid user-agent header")?,
    );
    headers.insert(ACCEPT, HeaderValue::from_static("application/json"));
    headers.insert(ACCEPT_ENCODING, HeaderValue::from_static("gzip"));

    let client = Client::builder()
        .default_headers(headers)
        .build()
        .context("build HTTP client")?;

    let cik = normalize_cik(&opts.cik)?;
    let base = "https://data.sec.gov";
    let targets = vec![
        (
            format!("{base}/api/xbrl/companyfacts/CIK{cik}.json"),
            format!("companyfacts_{cik}.json"),
        ),
        (
            format!("{base}/submissions/CIK{cik}.json"),
            format!("submissions_{cik}.json"),
        ),
    ];

    for (idx, (url, filename)) in targets.iter().enumerate() {
        fetch_with_cache(
            &client,
            url,
            &opts.out_dir,
            filename,
            opts.refresh,
            &opts.out_dir.join("request_log.csv"),
        )?;

        if opts.max_per_sec > 0 && idx + 1 < targets.len() {
            let delay_ms = (1000.0 / opts.max_per_sec as f64).ceil() as u64;
            thread::sleep(Duration::from_millis(delay_ms));
        }
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

fn fetch_with_cache(
    client: &Client,
    url: &str,
    out_dir: &Path,
    filename: &str,
    refresh: bool,
    log_path: &Path,
) -> Result<()> {
    let out_path = out_dir.join(filename);
    if out_path.exists() && !refresh {
        log_request(log_path, url, "cached")?;
        return Ok(());
    }

    let resp = client.get(url).send().with_context(|| format!("GET {url}"))?;
    let status = resp.status();
    if !status.is_success() {
        log_request(log_path, url, &status.as_str())?;
        anyhow::bail!("request failed {status} for {url}");
    }
    let bytes = resp.bytes().context("read response bytes")?;

    let tmp_path = out_path.with_extension("tmp");
    let mut file = fs::File::create(&tmp_path)
        .with_context(|| format!("create {}", tmp_path.display()))?;
    file.write_all(&bytes)
        .with_context(|| format!("write {}", tmp_path.display()))?;
    fs::rename(&tmp_path, &out_path)
        .with_context(|| format!("rename {}", out_path.display()))?;

    log_request(log_path, url, status.as_str())?;
    Ok(())
}

fn log_request(log_path: &Path, url: &str, status: &str) -> Result<()> {
    let timestamp = OffsetDateTime::now_utc()
        .format(&Rfc3339)
        .unwrap_or_else(|_| "unknown".to_string());
    let line = format!("{timestamp},{url},{status}\n");

    let mut file = fs::OpenOptions::new()
        .create(true)
        .append(true)
        .open(log_path)
        .with_context(|| format!("open {}", log_path.display()))?;
    file.write_all(line.as_bytes())
        .with_context(|| format!("write {}", log_path.display()))?;
    Ok(())
}
