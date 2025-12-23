# Project Roadmap: Ping-Networks

This roadmap outlines the planned development and future direction for the Ping-Networks project. It is a living document and may be updated periodically to reflect changing priorities and new insights.

## Completed Milestones

### v1.1.0 (Recent Release) ✅
*   **Critical Bug Fixes:**
    *   Fixed subnet calculation bug causing empty IP addresses
    *   Fixed ping execution - replaced placeholder code with actual Test-Connection logic
    *   Resolved parameter splatting issues in main script
*   **Code Quality Improvements:**
    *   Added comprehensive inline documentation for all functions
    *   Detailed comments explaining subnet calculation methodology
    *   Improved verbose output with informative progress messages
    *   Automatic cleanup of default Excel sheets
*   **Enhanced Reliability:**
    *   Better error handling and validation
    *   Division-by-zero protection in progress calculations
    *   Proper COM object disposal

### v1.0.0 ✅
*   **Core Functionality Stabilization:** `Get-UsableHosts` and `Start-Ping` functions are robust and tested.
*   **Excel COM Automation Reliability:** Hardened COM object handling for deterministic cleanup.
*   **Usability and UX Consistency:** Refined parameter handling, error messages, and default behaviors.
*   **Module Metadata and Documentation:** Completed `README.md` and established clear repository structure.

## Current Focus (v1.2.0 Planning)

## Short-Term Goals (Post v1.0.0)

*   **Enhanced Input Options:**
    *   Support for CIDR notation directly in the input Excel file.
    *   Allowing input from CSV files or direct PowerShell arrays/objects.
*   **Improved Ping Customization:**
    *   Adding options for custom packet sizes, TTL, and fragmentation.
    *   Support for ICMP types other than echo request (e.g., timestamp).
*   **Advanced Host Discovery:**
    *   Integration with ARP table scanning for local network discovery.
    *   Option to perform DNS lookups for all hosts, not just reachable ones.
*   **More Output Formats:**
    *   Direct export to SQL databases.
    *   JSON/XML output options for programmatic consumption.

## Long-Term Vision

*   **Web-Based UI:** Developing a lightweight web interface for easy network scanning and visualization, potentially using PowerShell Universal Dashboard or a similar framework.
*   **Agent-Based Scanning:** Exploring the possibility of deploying agents on remote machines for distributed scanning.
*   **Integration with IT Automation Platforms:** Seamless integration with platforms like Ansible, Puppet, or Microsoft SCCM.
*   **Reporting and Alerting:** Generating comprehensive reports and integrating with alerting systems for network changes or issues.
*   **Cross-Platform Compatibility:** Investigating compatibility with PowerShell Core on Linux/macOS for broader reach (requires re-evaluation of COM dependencies).

## Contributing

We welcome contributions from the community! If you have ideas, bug reports, or want to contribute code, please refer to the `CONTRIBUTING.md` (to be created) for guidelines.
