require("dotenv").config({ path: require("path").join(__dirname, "../.env") });

const path = require("path");
const express = require("express");
const session = require("express-session");

const authRoutes = require("./routes/authRoutes");
const dashboardRoutes = require("./routes/dashboardRoutes");
const { BACKEND_BASE_URL } = require("./services/backendApiService");

const app = express();
const PORT = process.env.PORT || 3000;

app.set("view engine", "ejs");
app.set("views", path.join(__dirname, "views"));

app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, "../public")));

app.use(
  session({
    secret: process.env.SESSION_SECRET || "dental-gate-secret-key",
    resave: false,
    saveUninitialized: false,
    cookie: {
      maxAge: 1000 * 60 * 60 * 4,
    },
  }),
);

app.use((req, res, next) => {
  res.locals.currentUser = req.session.user || null;
  res.locals.flash = req.session.flash || null;
  delete req.session.flash;
  next();
});

app.use("/", authRoutes);
app.use("/", dashboardRoutes);

app.use((err, req, res, next) => {
  if (err) {
    req.session.flash = {
      type: "error",
      message: err.message || "Something went wrong while processing your request.",
    };
    return res.redirect("/dashboard");
  }
  return next();
});

app.use((req, res) => {
  res.status(404).render("404", { title: "Page Not Found" });
});

app.listen(PORT, () => {
  console.log(`Dashboard running on http://localhost:${PORT}`);
  console.log(`Backend API: ${BACKEND_BASE_URL}`);
});
