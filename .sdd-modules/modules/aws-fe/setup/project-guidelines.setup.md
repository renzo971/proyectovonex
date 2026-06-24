# Best practices and guidelines

1. Refactor the code to avoid monoliths:
    - WHY: monoliths are hard to maintain, debug, update and reuse;
    - an optimal component file should has about 150 code lines;
    - over 300 code lines it earns the certificate of monolith;
    - the previous considerations can be applied also to all not-component files;
2. keep your code "isolated" as much as possible:
    - e.g. all the components related to an app section is located in the "src/pages/section-name" folder;
    - WHY: an isolated set of components is more maintanable and it can be replaced entirely if the situation requires it;
    - WHY: an isolated set of components doesn't have impact to the rest of the application;
    - if you are 200% sure that your code should be shared to the whole application scope, the following places are available:
        - src/api = it must contains only the functions that define the API XHR calls;
        - src/components = it must contains only the basic components that really need to be reused across all the application;
        - src/helpers = it must contains only the static functions that solve common needs across all the components;
        - src/models = it must contains all the business logic models to interact with the APIs;
3. respect the KISS principle and add comments to your code when it can help to undestand it:
    - WHY: if you respect the KISS principle, most of your code should be easily understandable. When it isn't possible, the comments applied should help other developers to undestand it;
4. avoid to define a new redux store when it is not necessary:
    - WHY: the state managed in the redux store require more effort to be developed, maintained and tested;
    - WHY: the state managed in the redux store doesn't support not-serializable values (Date, File etc.);
    - prefer the local state (useState) if it can suit the case;
    - evaluate to create a redux store only when one of the following cases happens:
        - the state is required by multiple macro-areas;
            - e.g. the "user" store share the auth data to all the app components;
        - you need to cache/persist data after the components deallocation;
            - e.g. caching a list provided by an API response
5. if a feature requires 5 or more components, organize it in a subfolder;
    - WHY: components organized by dedicated folders make their scope more understandable and maintainable;
6. if your component contains a lot of pure logic (e.g. form logics), evaluate to organize the logic with hooks functions in a dedicated file in the same component folder:
    - WHY: moving the logic in a dedicated file make both the component and the logic more readable and maintainable;
7. all the codebase statements (variable, comments, file names etc.) must be in english:
    - WHY: we work in an international work environment;
8. avoid the "any" typing as much as possible:
    - WHY: the "any" type makes the use of typescript useless;
    - if you don't have the time to search the right typing for your case, track it and fix it at a later time.
    9. Avoid the installation of extra NPM packages:
    - WHY: any new package you add, force the future maintainance team to learn it causing the increase of maintainance effort.
    - WHY: any new package you add, require a security update.
    - WHY: any new package you add, increase the overall app complexity.
