# ReScript NextJS Starter

This is a NextJS based template with following setup:

- Full Tailwind v2 config & basic css scaffold (+ production setup w/ purge-css & cssnano)
- [ReScript](https://rescript-lang.org) + React
- Basic ReScript Bindings for Next
- Preconfigured Dependencies: `reason-react`

## Development

Run ReScript in dev mode:

```
npm run res:start
```

In another tab, run the Next dev server:

```
npm run dev
```

## Tips

### Filenames with special characters

ReScript > 8.3 now supports filenames with special characters: e.g. `pages/blog/[slug].res`.
If you can't upgrade yet, you can create a e.g. `pages/blog/[slug].js` file, a `re_pages/blog_slug.re` file and then reexport the React component within the `[slug].js` file.

We recommend upgrading to the newest ReScript (bs-platform) version as soon as possible to get the best experience for Next!

### Fast Refresh & ReScript

Make sure to create interface files (`.resi`) for each `page/*.res` file.

Fast Refresh requires you to **only export React components**, and it's easy to unintenionally export other values than that.

For the 100% "always-works-method", we recommend putting your ReScript components in e.g. the `src` directory, and re-export them in plain `pages/*.js` files instead (check out the templates initial `pages` directory to see how we forward our React components to make sure we fulfill the Fast-Refresh naming conventions).

## Useful commands

Build CSS seperately via `postcss` (useful for debugging)

```
# Devmode
npx postcss styles/main.css -o test.css

# Production
NODE_ENV=production npx postcss styles/main.css -o test.css
```

## Test production setup with Next

```
# Make sure to uncomment the `target` attribute in `now.json` first, before you run this:
npm run build
PORT=3001 npm start
```

