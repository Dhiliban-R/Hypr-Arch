/* globals showInPageNotification */
function getBrowser() {
  if (window['chrome']) {
    return window['chrome'];
  } else if (window['browser']) {
    return window['browser'];
  }
  return undefined;
}

getBrowser().runtime.sendMessage({
  'request': 'getNotificationData'
}, function (notificationData) {
  (async () => {
    await showInPageNotification(notificationData, true);

    /**
     * We cannot use resizeTo because it includes the title bar height
     * and we do not have any way of calculating that.
     * So we could calculate delta from body dimensions and use resizeBy instead
     * Still, we don't resize the width: we fix it to 340px which is standard size
     * on macOS
     * We don't resize the height - because it can visibly appear jumping to users
     * if we are resizing after the notification has loaded
     * This comment is left as warning: please don't bother dynamically resizing the
     * notification window
     */
  })();
});