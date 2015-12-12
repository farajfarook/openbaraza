import javax.swing.event.EventListenerList;

public class MyClass { // Create the listener list 

	protected EventListenerList listenerList = new javax.swing.event.EventListenerList();

    public synchronized void makeAction(MyEvent evt) {
		fireMyEvent(evt);
    }
	
	// This methods allows classes to register for MyEvents 
	public void addMyEventListener(MyEventListener listener) {
		listenerList.add(MyEventListener.class, listener); 
	} 
	
	// This methods allows classes to unregister for MyEvents 
	public void removeMyEventListener(MyEventListener listener) {
		listenerList.remove(MyEventListener.class, listener); 
	} 

	// This private class is used to fire MyEvents 
	void fireMyEvent(MyEvent evt) { 
		Object[] listeners = listenerList.getListenerList(); 

		// Each listener occupies two elements - the first is the listener class 
		// and the second is the listener instance 
		for(int i=0; i<listeners.length; i+=2) { 
			if (listeners[i]==MyEventListener.class) { 
				((MyEventListener)listeners[i+1]).myEventOccurred(evt); 
			} 
		} 
	} 
} 
