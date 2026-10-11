// Leave now: replace this page rather than navigate from it, so the back
// button doesn't bring it straight back. Without JavaScript the link still
// works as an ordinary link.
document.getElementById('leave-now').addEventListener('click', function (event) {
  event.preventDefault();
  window.location.replace(this.href);
});
