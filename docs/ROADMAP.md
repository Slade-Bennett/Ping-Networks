# Project Roadmap: Ping-Networks

This roadmap outlines the planned development and future direction for the Ping-Networks project. It is a living document and may be updated periodically to reflect changing priorities and new insights.

## Current Focus (v1.0.0 Release)

*   **Core Functionality Stabilization:** Ensuring the `Get-UsableHosts` and `Start-Ping` functions are robust, efficient, and thoroughly tested.
*   **Excel COM Automation Reliability:** Hardening COM object handling for deterministic cleanup and preventing orphaned processes.
*   **Usability and UX Consistency:** Refining parameter handling, error messages, and default behaviors for a smooth user experience.
*   **Module Metadata and Documentation:** Completing the `README.md`, `.psd1` module manifest, and establishing a clear repository structure.

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
