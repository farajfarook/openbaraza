public class Mood {
    public static final Mood HAPPY   = new Mood( "happy" );
    public static final Mood ANNOYED = new Mood( "annoyed" );
    public static final Mood ANGRY   = new Mood( "angry" );
    
    private String _mood;
    
    public String toString() {
        return _mood;
    }
    
    private Mood( String mood ) {
        _mood = mood;
    }
    
}

