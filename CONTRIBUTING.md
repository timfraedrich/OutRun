# Contribution Guidelines

Thank you for considering to contribute to this project. Before you get started there are some things you need to.

## Setup the project

Setting up the project is simple, just follow these steps:

1. **Clone the repository**

    To clone the repository either use a git client and paste the repository's URL [https://github.com/timfraedrich/OutRun.git](https://github.com/timfraedrich/OutRun.git) or clone it via the command line:

        git clone https://github.com/timfraedrich/OutRun.git

2. **Setup needed libraries**

    OutRun uses CocaoPods for external libraries. To setup CocaoPods either use their desktop client or the command line. For the command line first navigate to the just cloned repository

        cd OutRun

    And then simply run

        pod install

3. **Change XCode Project settings**

    First open the just generated `OutRun.xcworkspace`. This will be the file to open to get to work on the project in the future.

    NOTE: Do not use the `OutRun.xcodeproj` file, it does not include the libraries needed in the project and you will not get it to compile without these

    Since you will not use the same developer account as when the app gets published just remove the `Team` attribute in `Project Settings > Signing and Capabilities` or change it to your own if you want to install the app on anything other than a simulator.

    You might also need to change the `Bundle Identifer` to get the app working since it is already registered on the publishing Apple Developer Account.

**Finished.** You now have a working version of the project on your computer.

Should there be any issues while setting up the project just create an issue on the [issue page](https://github.com/timfraedrich/OutRun/issues) we can probably sort it out.

## Rules for contribution

There are no solid rules for contribution yet, that will probably be a community effort to sort out, but so far you should beware the following things when adding new code (even though not even all the initial code conforms to these rules):

* **Use Spaces Not Tabs.** I personally perfer spaces to tabs and used them in the entire project, so new code should also be indented with 4 spaces rather than with a tab.

* **Start a file with the license notice.** Every file should start with the following notice (and its file name):

        [FILENAME]

        OutRun
        Copyright (C) 2020 Tim Fraedrich <timfraedrich@icloud.com>

        This program is free software: you can redistribute it and/or modify
        it under the terms of the GNU General Public License as published by
        the Free Software Foundation, either version 3 of the License, or
        (at your option) any later version.

        This program is distributed in the hope that it will be useful,
        but WITHOUT ANY WARRANTY; without even the implied warranty of
        MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
        GNU General Public License for more details.

        You should have received a copy of the GNU General Public License
        along with this program.  If not, see <http://www.gnu.org/licenses/>.

* **Properly document your code.** When you contribute new code it should be well documented so everyone understands what it is used for, for that I stared using the swift in-line documentation (although a lot of the app is still undocumented). Document like this:

    ```swift
    /// There should be a short description on every class, struct, enum or protocol
    class SomeClass { }

    /**
     If you want you can also create more elaborate documentation if you feel like it is appropriate
     - Note: For example if you want to note something
     */
    class AnotherClass {

        /// Every property inside a class, etc. should have a small and on-point description
        var someProperty: SomeObject

        /**
         Functions should always have more detail on what they will do, starting with a good summery
         - parameter attr1: then a list of the parameters
         - parameter attr2: which should clearly state what they are for
         - returns: and if the function returns it should be described what exactly it returns
         */
        func someMethod(attr1: SomeObject, attr2: AnotherObject) -> ReturnObject { }

        /**
         The same should be applied to initialisers
         */
        init() { }

    }
    ```

## Get started

Now that you have a working instance of the project and know the small subset of rules to look out for you can basically get started.

To get a task you can visit the [issue page](https://github.com/timfraedrich/OutRun/issues) and look for an appropriate issue for you.

Once you feel like sharing your code, even if it is just to get some feedback, just open a pull request.

Good Coding!
