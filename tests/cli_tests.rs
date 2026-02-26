use assert_cmd::Command;
use predicates::prelude::*;

fn cmd() -> Command {
    Command::cargo_bin("projek-1").unwrap()
}

#[test]
fn no_subcommand_shows_usage() {
    cmd()
        .assert()
        .failure()
        .stderr(predicate::str::contains("Usage"));
}

#[test]
fn unknown_subcommand_errors() {
    cmd()
        .arg("bogus-command")
        .assert()
        .failure()
        .stderr(predicate::str::is_empty().not());
}

#[test]
fn fetch_sec_without_user_agent_errors() {
    cmd()
        .arg("fetch-sec")
        .env_remove("SEC_USER_AGENT")
        .assert()
        .failure()
        .stderr(predicate::str::contains("missing SEC User-Agent"));
}

#[test]
fn fetch_sec_with_env_var_passes_arg_parsing() {
    // With SEC_USER_AGENT set, the command should not fail with
    // "missing SEC User-Agent". It may succeed (if network is up)
    // or fail for other reasons, but never for user-agent resolution.
    let assert = cmd()
        .arg("fetch-sec")
        .env("SEC_USER_AGENT", "TestBot test@example.com")
        .assert();
    assert.stderr(predicate::str::contains("missing SEC User-Agent").not());
}

#[test]
fn run_pipeline_missing_price_errors() {
    cmd()
        .args(["run-pipeline", "--as-of-date", "2026-01-01"])
        .env("SEC_USER_AGENT", "TestBot test@example.com")
        .assert()
        .failure()
        .stderr(predicate::str::contains("--price"));
}

#[test]
fn run_pipeline_missing_as_of_date_errors() {
    cmd()
        .args(["run-pipeline", "--price", "100.0"])
        .env("SEC_USER_AGENT", "TestBot test@example.com")
        .assert()
        .failure()
        .stderr(predicate::str::contains("--as-of-date"));
}

#[test]
fn run_pipeline_non_numeric_price_errors() {
    cmd()
        .args(["run-pipeline", "--price", "abc", "--as-of-date", "2026-01-01"])
        .env("SEC_USER_AGENT", "TestBot test@example.com")
        .assert()
        .failure()
        .stderr(predicate::str::is_empty().not());
}
