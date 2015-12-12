public class action implements MyEventListener {

	public static void main(String args[]) {
		action a = new action();
		a.doIt();
	}

	public void doIt() {
		MyClass c = new MyClass(); 
		action b = new action();

		// Register for MyEvents from c 
		c.addMyEventListener(b); 

		MyEvent evt = new MyEvent("kamau");
		c.makeAction(evt);
	}

	public void myEventOccurred(MyEvent evt) {
		System.out.println("Event happened");
	} 
}
