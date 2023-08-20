# SEQPrepare

**SEQPrepare** is an app for current and prospective residents of Brisbane, Moreton Bay and Sunshine Coast to better help prepare for any upcoming disasters. It offers a number of useful features for building resiliency:

- Viewing current risks - such as ratings for fires nearby and monitoring nearby water levles
- Understanding long-term risks for the property - based on data from past events and other data
- Building a survival plan that focuses especially on risks that are especially prevalant in the user's region

## Other notable features

- Reuses recognisable and familiar branding, such as the use of the [Australian Fire Danger Rating System](https://afdrs.com.au/)
- The app should be screen reader friendly, as it uses semantic labels for visual element including the AFDRS watermelon.

## Interactive demo

The web version of the app is currently hosted at [seqprepare.xyz](https://seqprepare.xyz). Alternatively, you can grab the .apk from [Releases](/releases/) and install this on an Android or ChromeOS device. 

## Compiling
### App
The app is built with [Flutter](https://flutter.dev)

## Datasets used
A wide variety of datasets are used in this project:

- [Fire Danger Ratings 4 Days (QLD)](ftp://ftp.bom.gov.au/anon/gen/fwo/IDQ13016.xml) from BOM - used to show today's fire danger rating to the user when they open the app. 
- [Current Bushfires and Warnings](https://www.qfes.qld.gov.au/data/alerts/bushfireAlert.xml) from QFES - used to discover whether there are any bushfires close to the user and advise them of a possible course of action based on current warnings.

## Current 