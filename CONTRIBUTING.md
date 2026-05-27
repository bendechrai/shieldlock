# Contributing to ShieldLock

First off, thank you for considering contributing to ShieldLock! It's people like you who make the open-source community such an amazing place to learn, inspire, and create.

## Code of Conduct

By participating in this project, you agree to maintain a respectful, welcoming, and professional environment for everyone.

## How Can I Contribute?

### Reporting Bugs

If you find a bug, please open an issue in our GitHub issue tracker. Be sure to include:
- A clear, descriptive title.
- Your macOS version and device model (e.g., MacBook Air M2, macOS 14.4).
- Exact steps to reproduce the issue.
- Any crash logs or relevant debug messages from the console.

### Suggesting Enhancements

We welcome suggestions for new features! To suggest an enhancement:
- Check first if the feature has already been suggested or implemented.
- Open an issue and describe the feature, explaining why it would be useful and how it should work.

### Submitting Pull Requests

If you'd like to contribute code:
1. Fork the repository.
2. Create a new branch for your feature or bug fix:
   ```bash
   git checkout -b feature/my-new-feature
   ```
3. Make your changes.
4. Ensure your changes compile perfectly by running the build script:
   ```bash
   ./build.sh
   ```
5. Commit your changes with a clear and descriptive commit message.
6. Push to your fork and submit a Pull Request to the main repository.

## Development Setup

To work on ShieldLock locally:
- Clone the repository.
- Examine `./Sources/main.swift` and `./Sources/LockWindow.swift` for implementation details.
- Build the app bundle using `./build.sh`.
- Test locally (make sure to grant Accessibility permissions to the built `./build/ShieldLock.app`).
