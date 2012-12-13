#Cocoa Hash Function Visualizer

![](http://cl.ly/image/3z171w0z1503/screenshot_hv.png "Sample screenshot of hash/bucket views side by side")

The goal of this project is mostly for personal learning experience, and to better grasp some of the basic concepts involved in hash table design and implementation. This small project was inspired by a post on Stack Exchange in which the commenter gave a well-written response as well as some intriguing graphics. I [posted](http://programmers.stackexchange.com/questions/177260/hash-algorithm-randomness-visualization) looking for further insight in how to create such images, then attempted to generate them myself.

What I am releasing here is a basically fully functional utility for visualizing both hash function distribution as well as compression distribution (bucket depth across the hash table).

The cool thing is that I have tried to make this as flexible as possible so that you can _very_ easily add your own hash/compression functions and see how they behave as well. I'll talk about how that works in a moment.

So what are we even looking at when we see the top image? Well, imagine having an array of length n, then inserting all the hashes your input allows you to generate inside it. Take that, and split it up so that each sqrt(n) chunk stacks on top of its chronological predecessor. You get as a result a sqrt(n) x sqrt(n) image with lots of individual data points. It is simply colorized by hue to make it look nice and perhaps help notice patterns along the horizontal shadings. The right view is illustrating a very nice, level compression distribution.
 
##Performance

I found this to be an excellent opportunity to learn as much about Grand Central Dispatch (GCD) as possible. Implementing it correctly enabled my MacBook Air to perform the computations required (in some cases 2+ Billion) in fairly reasonable amounts of time. While I'm sure more experienced developers could improve performance even further, I believe that the the app's current runtime is very reasonable.


##Preferences

![Preferences Window](http://cl.ly/image/1V1B3D152t26/preferences_window.png)

When running this application, there are several preferences that can be configured:

*	**Queue Size**
	The queue size simply specifies the number of items that will be buffered before drawing them onto the image. Since drawing is an expensive operation to do in rapid succession, the app breaks it up into a definable chunk and does all of those drawing operations at once.
	
*	**Point Size**
	This preference specifies the size of the point to be drawn. That is, for each tiny point to be drawn, how many pixels it will color to represent that data point. The default is 1. I currently have no way of knowing just how this affects HiDPI displays, but it may be necessary to use this to make data points visible.
	
*	**Resolution**
	The resolution preference allows for more granular control over how large the image will be drawn in memory. Included simply as a scalar value, this simply scales the image in memory to be X-number of times larger than the default 650x650 image size. This makes it all very simple and keep the proportions constrained.
	
*	**Hash Table Length**
	The hash table length is important in ensuring the bucket distribution simulation shows you the correct distribution.
	
*	**Bucket Image Height**
	This preference may be a little confusing, but I found it necessary. This changes the ratio of the height so that the buckets are effectively vertically stretched. If left where it normally would otherwise be (100%), the little dots would line up along the bottom pixel row and that's all you would see. Having this set to a custom value makes it so that you can tailor it to your data and hopefully see it more clearly.
	
*	**Dictionary File**
	This can be used to change the Dictionary Mode input file. If the selected file is not a plain text file with newline delimiters, I have no idea what it will do. Please just make sure that you feed it proper data.
	
*	**Ticket Cell Maximum Value**
	This sets the upper bound on the range of possible values that can be used to generate a "lottery ticket", with which a hash may be computed. Details in the next section.	

## Dictionary vs Lottery Modes

![Mode Selection](http://cl.ly/image/3b2k2m461a3R/Screen%20Shot%202012-12-12%20at%204.03.10%20PM.png)

There are two modes that the app can operate in, highlighted in the next section. One of which is a "Dictionary" mode. This takes words as input and uses ASCII values to generate a byte array. This can then be used to generate a hash. The idea is that a given hash function may only need to operate on a specific data set, which this could likely be helpful in testing.

The second, aka "Lottery", mode is one that generates hashes based on a lottery ticket scheme. In fact, this was the entire premise that I started to build this app around. It comes from a homework problem that we had recently discussing hash functions. The idea is that given a particular range, we can generate tickets with cells from 1->n in the format X X X X X X. Each X being its own cell. The maximum I've included is 36, which will generate 36^6 tickets/hashes. This will take a long time for most computers, but it is certainly possible to do in a few hours on a powerful machine.

The reason I chose to keep that very specific example is because it allowed me to see how well a continuous set of inputs would behave, and whether the hash/compress functions could distribute evenly.

## Adding Your Own Hash Functions

I made adding in your own functions as simple as possible! In fact, setting it up is nearly painless. Once you've downloaded everything, open the Xcode project and make a subclass of `NUHashModule`. This is sort of the master class in handling all the GCD and drawing code, so it's probably best to leave it alone. However, your subclass should only override three methods:

* `- (NSString *)title;` This method just makes everything more friendly so that when the app asks you which algorithm you would like to visualize, you have a friendly title to look at. Have it return `@"John's Hash"` for all it matters, it's really just for you to see.

* `- (unsigned long long)hashForComponents:(NUHashComponents)component;` This is where you will compute your hashes. Simply use the component struct to perform your computations and return the finished hash. What is in that struct, you ask? There are two simple attributes inside: 
	* `bytes`  - The byte array that contains all of the data in the word or ticket to be hashed
	* `length` - The number of items that are in that array

* `- (unsigned long long)bucketIndexForHash:(unsigned long long)hash;` This method simply gives you a place to compute the compression for a given hash. **Remember that in the interest of performance, make this as lean as possible.**

Once you've done all of that, the app will use the Objective-C Runtime to handle finding and loading your class, which is awesome. Basically just subclass `NUHashModule` and fill in the blanks and it should be good to go from there. Cool, eh?

## What's next?

I actually have no idea what, if anything, I want to do with this. If people are interested and seem to like it, perhaps I will continue to improve it.

Please let me know what you think, or if you have any questions:

* Twitter - [@clstr0ud](https://twitter.com/clstr0ud)
* Email - chris [at] elevecreations · net

## Credits
* Original idea - SE user Ian Boyd ([via Stack Exchange](http://programmers.stackexchange.com/a/145633/73699))
* Grabbing subclasses from the Objective-C Runtime - [Cocoa With Love](http://cl.ly/0G1A07283Z1O)
* Special thanks to [Dr. George Rouskas](http://rouskas.csc.ncsu.edu) at NC State University for teaching me these concepts in the first place