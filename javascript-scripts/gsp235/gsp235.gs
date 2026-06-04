/**
* @OnlyCurrentDoc
*/

function sendMap() {
    var sheet = SpreadsheetApp.getActiveSheet();
    var address = sheet.getRange("A1").getValue();
    var map = Maps.newStaticMap().addMarker(address);
    GmailApp.sendEmail("<YOUR_EMAIL>", "Map", 'See below.', {attachments:[map]});
}