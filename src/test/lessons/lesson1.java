/**
 *  * The HelloWorldApp class implements an application that
 *   * simply prints "Hello World!" to standard output.
 *    */
class lesson1 {

    public static void main(String[] args) {

        System.out.println("Hello World!"); // Display the string.

	String name = "dennis";
	lesson2 ls2 = new lesson2();
	ls2.writeName(name);

	Bicycle bc1 = new Bicycle();
	Bicycle bc2 = new Bicycle();
	MountainBike bc3 = new MountainBike();

	bc1.printStates();
	bc1.speedUp(5);
	bc1.changeCadence(2);
	bc1.printStates();

	bc2.changeGear(2);
	bc2.speedUp(15);
	bc2.printStates();

	bc3.changeGear(2);
	bc3.speedUp(15);
       	bc3.printStates();

	Bicycle[] bc_ar = new Bicycle[5];
	for(int i = 0; i<4; i++) {
		bc_ar[i] = new Bicycle();
		bc_ar[i].printStates();
	}
    }

}

