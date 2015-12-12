public class ADayInTheLife {
    public static void main( String [] args ) {
        MrHappyObject happy = new MrHappyObject();
        MoodListener  sky   = new Sky();
        MoodListener  birds = new FlockOfBirds();

        happy.addMoodListener(sky);
        happy.addMoodListener(birds);
        
        System.out.println( "Let's pinch MrHappyObject and find out what happens:" );
        happy.receivePinch();
        
        System.out.println("");
        System.out.println( "Let's hug MrHappyObject and find out what happens:" );
        happy.receiveHug();
        
        System.out.println("");
        System.out.println( "Now, let's make MrHappyObject angry and find out what happens:" );
        System.out.println("");
        System.out.println("one pinch:");
        happy.receivePinch();

        System.out.println("");
        System.out.println("second pinch, look out:");
        happy.receivePinch();
    }
    
}

