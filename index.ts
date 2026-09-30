import { App } from "@elements/app";
import config from "#config";
import home from "#app/pages/home";
import signin from "#app/pages/signin";
import space from "#app/pages/space";
import wikiPage from "#app/pages/wiki-page";
import history from "#app/pages/history";
import search from "#app/pages/search";
import members from "#app/pages/members";
import invite from "#app/pages/invite";
import { clearThisHost } from "#app/shared/services/presence";
import notFound from "#app/pages/errors/not-found";
import unhandled from "#app/pages/errors/unhandled";

const app = new App();

app.route("/", home);
app.route("/signin", signin);
app.route("/s/:slug", space);
app.route("/s/:slug/:pageId", wikiPage);
app.route("/s/:slug/:pageId/history", history);
app.route("/search", search);
app.route("/admin/members", members);
app.route("/invite/:token", invite);

app.error((req, res, err) => {
  switch (err.statusCode) {
    case 404:
      return notFound(req, res, err);

    default:
      return unhandled(req, res, err);
  }
});

app.start(config);

// Presence rows this host left behind when it last stopped.
clearThisHost();
