# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog, and this project adheres to
Semantic Versioning (https://semver.org/spec/v2.0.0.html).

## [2.0.1] - 2024-01-16

### Fixed
- Patched autoscaling target CPU threshold rounding issue

## [2.0.0] - 2024-01-15

### Added
- OAuth2 authentication support
- API gateway integration
- Rate limiting functionality
- Advanced monitoring with Prometheus and Grafana
- Database and cache support

### Changed
- BREAKING: Changed default web server from nginx to httpd
- BREAKING: Changed service type from ClusterIP to NodePort
- BREAKING: Changed default port from 80 to 8080
- Improved resource allocation
- Enhanced autoscaling configuration

### Removed
- BREAKING: Removed basic authentication (replaced with OAuth2)

## [1.1.0] - 2024-01-10

### Added
- Horizontal Pod Autoscaler support
- Health check endpoints
- Metrics collection

### Changed
- Increased default replica count from 2 to 3
- Updated nginx image from 1.21 to 1.22

## [1.0.0] - 2024-01-05

### Added
- Initial release of webapp-chart
- Basic nginx deployment
- ClusterIP service
- Basic authentication and logging
