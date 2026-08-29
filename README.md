# Miliastra Wonderland Ode Tracker

A lightweight, web-based tracker designed to monitor, graph, and analyze your pulling history (Odes). Manage multiple accounts, visualize your luck across Event and Standard banners, and safely back up your data locally.

## Features
* **Multi-Account Management:** Add, rename, and switch between different UIDs seamlessly.
* **Visual Analytics:** View grouped pull histories via interactive bar charts.
* **Data Portability:** Export your active account history as a `.json` backup and import it anywhere.
* **Clean UI:** Responsive design that handles everything from raw PowerShell outputs to active legacy backups.

## Getting Started
1. Run the `miliastra-export.ps1` script to securely grab your local game log history.
2. Open `index.html` in your browser.
3. Click **Auto Import** and paste the script's output, or upload a `.json` file via the Settings menu.
4. Your graphs will automatically populate and merge with any existing data.

## Note on Privacy
All data processing and storage happens completely locally in your browser. No account information or pull histories are sent to external servers.