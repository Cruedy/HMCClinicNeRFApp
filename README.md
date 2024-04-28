# User Guide
## Instructions View
### Instructions
These instructions help the user when they initially open up the app:
<br>
<img src="docs/assets_readme/IntroInstructions.PNG" height="342"/>
<br>

It breaks down what the user should do in future steps and recommends how they can can get the best resulting model.

### Start Project
There is a *Start Projext* button at the bottom of the screen, which the user presses to enter the name of their project. Once the project is started, this will pop up:
<br>
<img src="docs/assets_readme/CreateProject.PNG" height="342"/>
<br>

The user can enter any name they want for the project, then press the submit button to go to the next step.

## Bounding Box View
### Box Placement
The user is first prompted to place the bounding box the same surface that the product is on:
<br>
<img src="docs/assets_readme/PlaceBBox1.PNG" height="342"/>
<br>

This is done by tapping on the screen:
<br>
<img src="docs/assets_readme/PlaceBBox2.PNG" height="342"/>
<br>

### Enter Dimesions
Once the bounding box is placed, the user then enters the dimensions of the product. This is the second step because users of this app will usually already know the dimensions of their product.
<br>
<img src="docs/assets_readme/EnterDimensions.PNG" height="342"/>
<br>

### Adjustments
The last part of creating the bounding box is making adjustments. In this part the user can:
<br>
Translate the Bounding Box
<br>
<img src="docs/assets_readme/translate.PNG" height="342"/>
<br>
Rotate the Bounding Box
<br>
<img src="docs/assets_readme/rotate.PNG" height="342"/>
<br>
Re-scale the Bounding Box
<br>
<img src="docs/assets_readme/rescale.PNG" height="342"/>
<br>
Extend the Sides of Bounding Box
<br>
<img src="docs/assets_readme/extend.PNG" height="342"/>
<br>
This will help the app track the location of the object in each frame, and help the server process the model faster.

## Taking Images View
### Start Image Taking
<br>
<img src="docs/assets_readme/startImages.PNG" height="342"/>
<br>
In this view the user can take images. According to the *Intro Instructions* it is recommended that the user takes between 50-100 images. In order to initiate the image taking session, the user has to first press the *Begin Capture* button. 

### Automatic Capture
Once the *Begin Capture* button is pressed, the *Begin Capture* and *View Gallery* buttons will be replaced by *Pause Automatic Capture* and *View Gallery* buttons:
<br>
<img src="docs/assets_readme/continueImages1.PNG" height="342"/>
<br>
The app will let the user know if they need to speed up or slow down their movement around the product by showing the user their velocity and letting them know if their speed is appropriate. The automatic image taking will also speed up if the user is only moving slightly too fast or slow down if the user is only moving slightly too slow. Just so the user is aware of when images are being taken, the scene flashes each time an image is taken. The user can also pause the image taking session by pressing the *Pause Automatic Capture* button:
<br>

### Image Distribution
We also let the user know the distribution of images around the product by changing the color and opacity of the faces of the bounding box as images are being taken. Currently, we have the goal number of images taken per side set to 10. This is what the face of a bounding box looks like before images are taken of that side:
<br>
<img src="docs/assets_readme/startImages.PNG" height="342"/>
<br>
This is what the face of a bounding box looks like when 4 out of 10 images are taken of a side:
<br>
<img src="docs/assets_readme/continueImages1.PNG" height="342"/>
<br>
This is what the face of a bounding box looks like when 10+ out of 10 images are taken of a side:
<br>
<img src="docs/assets_readme/continueImages2.PNG" height="342"/>
<br>
This is what the bounding box looks like when you start taking images of another side:
<br>
<img src="docs/assets_readme/continueImages3.PNG" height="342"/>
<br>
This is what the bounding box looks like when you finish taking images of the other side:
<br>
<img src="docs/assets_readme/continueImages4.PNG" height="342"/>
<br>
Once the user is done taking images of every side of the product, the bounding box faces will be transparent. They can move on to looking at the images they took by pressing the *View Gallery* button.

## Gallery View
### Grid View
This is what they gallery view first looks like to a user when they move on from the image taking view:
<br>
<img src="docs/assets_readme/GridView.PNG" height="342"/>
<br>
In this view the user can check the images they took, delete usable images, and go back to take more images. 
### Detail View
In order to see the image in greater detail, the user can click on the image to see this view:
<br>
<img src="docs/assets_readme/DetailView.PNG" height="342"/>
<br>
To go back to the grid view from here, they can press the *Image Gallery* button in the top left corner. 
### Edit Collection View
Once the user looks at the images and figures out which one(s) they want to delete, they can click the *Edit* button in the top right corner to get this view:
<br>
<img src="docs/assets_readme/EditView.PNG" height="342"/>
<br>
In this view they can delete the images that are too blurry/don't have a good new view of the object.
### Retake Images
If they want to retake images to replace the ones they deleted, they can press the *Back to Camera* button on the bottom left side of the view. This button will bring the user back to this view:
<br>
<img src="docs/assets_readme/RetakeImage.PNG" height="342"/>
<br>
Once the user is satisfied with the images that they've compiled after viewing them in the gallery view, they can move onto sending the images over to the server by pressing the *Send Data to Server* button.

## Send Images to Server View

<img src="docs/assets_readme/SendToServer.PNG" height="342"/>

This view has 5 buttons that should be press in the order that they are presented on the screen. To start the process of generating a 3D model on the server side, the user should first press the *Send zip to Server* button. The user will be notified when this process is done. Then they can move on to pressing the *Generate Splatt* button, which will generate the 3D model from gaussian splatts. To view their model, the user should press *get video*. The button *get url* is available for the user to be able to view their 3D model on the Web View. The user can also have direct access to their results by pressing the *View Results* button.

# Developer Guide
## Running the App
Follow this guide to get the project in your xcode:
<br>
<a href="https://medium.com/@sayalee.blogs/using-xcode-with-github-repo-e4253cffa895" target="_blank">Xcode Repo Tutorial</a>






