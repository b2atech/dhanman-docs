# MkDocs Deployment Guide

## 1. Install MkDocs and Build Your Site

pip install mkdocs

Navigate to your MkDocs project folder (with mkdocs.yml), then build the static site:

mkdocs build

The static site files will be generated in the site/ directory.

---

## 2. Deploy MkDocs Site

You can deploy the static site/ folder on any static hosting platform.

### Option A: Deploy to GitHub Pages

1. Initialize git repo (if not already done):

git init  
git add .  
git commit -m "Initial commit"

2. Push to a GitHub repository.

3. Deploy using the built-in command:

mkdocs gh-deploy

This builds and publishes to the gh-pages branch.  
Access your site at:  
https://<username>.github.io/<repo>/

---

### Option B: Deploy on Your Own Web Server

1. Build the static site:

mkdocs build

2. Upload the contents of the site/ directory to your web server root (e.g., /var/www/html).

3. Configure your web server (Apache, Nginx, etc.) to serve the files.

---

### Option C: Deploy on Netlify or Vercel

1. Push your MkDocs project to a Git repo (GitHub, GitLab, Bitbucket).

2. Connect the repo to Netlify or Vercel.

3. Set build command to:

mkdocs build

4. Set the publish directory to:

site

5. Deploy the site.

---

## 3. Optional: Customize mkdocs.yml

Make sure your mkdocs.yml has the correct site_url for your deployment.

---

## 4. Useful Commands Summary

pip install mkdocs           # Install MkDocs  
mkdocs build                 # Build static site into site/ folder  
mkdocs serve                 # Preview site locally at http://127.0.0.1:8000/  
mkdocs gh-deploy             # Deploy to GitHub Pages automatically

---

Keep this guide handy for quick reference when deploying MkDocs!
