# Helm Versioning and Rollback Best Practices

## Versioning Strategy

- Major (X.0.0): Breaking changes, incompatible API changes
- Minor (X.Y.0): New features, backward compatible
- Patch (X.Y.Z): Bug fixes, backward compatible
- Always increment the chart version when making changes, and keep appVersion
  synchronized with the application version being deployed.

## Rollback Strategy

### Before Rollback
1. Identify the issue and root cause.
2. Check deployment history with `helm history <release>`.
3. Verify the target revision is known to be stable.
4. Plan rollback timing (use a maintenance window for production systems).

### During Rollback
1. Monitor the rollback process (pod readiness, service endpoints).
2. Verify application functionality immediately after rollback.
3. Check all dependent services and downstream consumers.

### After Rollback
1. Document the incident and the reason for rollback.
2. Plan a forward fix for the next release rather than staying rolled back long-term.
3. Update the changelog and release notes to reflect the rollback.

## Production Considerations

- Test all chart versions and rollback paths in a staging environment first.
- Implement health checks that can trigger automatic rollback.
- Maintain a changelog and per-version release notes, committed to git.
- Scan chart dependencies for vulnerabilities and use signed charts in production.
- Apply RBAC to restrict who can run `helm upgrade` and `helm rollback` in production namespaces.

## Common Pitfalls to Avoid

1. Not testing rollback procedures before they are needed in an incident.
2. Failing to clearly document and communicate breaking changes.
3. Inconsistent or non-semantic version numbering.
4. Insufficient monitoring around deployments and rollbacks.
5. Relying on manual, undocumented rollback steps instead of scripts and runbooks.

## Essential Commands Reference

```bash
# View release history
helm history <release-name>

# Rollback to the immediately previous revision
helm rollback <release-name>

# Rollback to a specific revision
helm rollback <release-name> <revision>

# Check release status
helm status <release-name>

# List all releases
helm list

# Get the values used for a release
helm get values <release-name>
