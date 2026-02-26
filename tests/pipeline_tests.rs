use std::fs;
use std::process::Command;
use tempfile::TempDir;

/// Helper: create a minimal .ps1 stub that exits with the given code.
fn write_stub(dir: &std::path::Path, name: &str, exit_code: i32) -> std::path::PathBuf {
    let path = dir.join(name);
    let content = if exit_code == 0 {
        "exit 0\n".to_string()
    } else {
        format!("exit {exit_code}\n")
    };
    fs::write(&path, content).expect("write stub");
    path
}

/// Run a PowerShell stub and return whether it succeeded.
fn run_ps_stub(script: &std::path::Path) -> bool {
    let status = Command::new("powershell.exe")
        .arg("-ExecutionPolicy")
        .arg("Bypass")
        .arg("-File")
        .arg(script)
        .status()
        .expect("launch powershell");
    status.success()
}

#[test]
fn stub_exit_zero_succeeds() {
    let tmp = TempDir::new().unwrap();
    let script = write_stub(tmp.path(), "pass.ps1", 0);
    assert!(run_ps_stub(&script));
}

#[test]
fn stub_exit_nonzero_fails() {
    let tmp = TempDir::new().unwrap();
    let script = write_stub(tmp.path(), "fail.ps1", 1);
    assert!(!run_ps_stub(&script));
}

#[test]
fn sequential_all_pass() {
    let tmp = TempDir::new().unwrap();
    let scripts: Vec<_> = (0..3)
        .map(|i| write_stub(tmp.path(), &format!("step{i}.ps1"), 0))
        .collect();
    for s in &scripts {
        assert!(run_ps_stub(s), "step {:?} should pass", s.file_name());
    }
}

#[test]
fn sequential_fail_fast() {
    let tmp = TempDir::new().unwrap();
    let s1 = write_stub(tmp.path(), "step1.ps1", 0);
    let s2 = write_stub(tmp.path(), "step2.ps1", 1);
    let s3 = write_stub(tmp.path(), "step3.ps1", 0);

    // Simulate run_ps fail-fast: stop on first non-zero
    let scripts = [s1, s2, s3];
    let mut failed_at: Option<usize> = None;
    for (i, s) in scripts.iter().enumerate() {
        if !run_ps_stub(s) {
            failed_at = Some(i);
            break;
        }
    }
    assert_eq!(failed_at, Some(1), "should fail at step2 (index 1)");
}
