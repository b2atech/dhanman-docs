#  CQRS Pattern

Each command or query is handled by a separate class in the Application layer.
- **CommandHandlers** modify data.
- **QueryHandlers** read optimized projections.
