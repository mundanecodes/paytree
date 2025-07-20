## [Unreleased]

## [0.2.0] - 2025-01-20

### Added
- Retryable error configuration for resilient payment processing
- Single `configure_mpesa` method with opinionated defaults
- Comprehensive response format with `success?`, `failed?`, `retryable?` methods
- Auto-loading of environment variables for configuration
- Enhanced error handling with specific M-Pesa error types
- Full test coverage for all payment operations

### Changed
- Simplified configuration API - removed multiple configuration methods
- Removed hook system (on_success/on_error) for cleaner architecture
- Improved documentation with clear examples and response formats

### Removed
- `configure_mpesa_sandbox` and `configure_mpesa_production` wrapper methods
- `auto_configure_mpesa!` method for simpler API
- Webhook handling (moved to application level)
- Hook system (on_success/on_error callbacks)

## [0.1.0] - 2025-07-14

### Added
- Initial release
- M-Pesa Daraja API integration
- STK Push, STK Query, B2C, B2B, C2B operations
- Configuration system with multiple providers support
- Comprehensive error handling and validation
- Rails integration support
