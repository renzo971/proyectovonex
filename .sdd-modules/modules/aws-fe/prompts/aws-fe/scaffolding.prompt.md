---
agent: neo
---

## Implementation Checklist

### 1. Init application
 - run the command `npx @dap-ui/gear@latest new -s my-app` and replace `my-app` with the project folder name
### 2. Move the generated folder content in the root folder
 - delete the `.git` folder inside the generated folder
 - move all the content of the generated folder to the root folder
 - delete the generated folder
### 3. Remove unnecessary files
 - delete the `architecture.png` file from the root folder
 - delete the `src/i18n/en.json` remove the node `example`
 - delete the `src/pages/` content 
 - delete the `src/routes/about.routes.tsx`file
 - delete the `src/routes/home.routes.tsx`file
### 4. Adjust the project to the new application
 - adjust the `src/routes/config.ts` removing the about and home routes imports and references 
 - adjust the `src/routes/appRoutes.tsx` removing the about and home routes imports and references
 - update the `package.json` file to set the `config.base` to the project name without the `ui` suffix
 - generate a trigram name starting from the application name and set the corresponding variable in `src/models/core.ts`
 - in the `src/index.tsx` file adjust the "render*" and the "unmount*" methods names based on your appTrigram;
 - in the `index.html` file adjust the "render*" and the "host*" parts to allow the stand-alone app run;
 
