# Best practices and guidelines for Unit Tests

1. Mock dependencies
    - WHY: we have not to test external libraries, 
    - WHY: we must isolate the test from side effects, 
2. Mock child components
    - WHY: we must isolate the test from side effects, 
3. Test the business logic only
    - WHY: the goal of a component is to reach the assigned business logic:
        - a wrong color have a low impact.
        - a wrong API call have a big impact.
4. Use the `beforeAll` and `beforeEach` blocks when it make sense.
    - WHY: the `before*` blocks can reduce the redundancy of the test statements.
5. use the unit test as measurement of your component implementation.
    - WHY: if your unit test is hard to be implemented, it means your component should be redesigned.