import java.util.logging.Logger;

public class nose {

    public static void main(String argv[]) {
		// Obtain a suitable logger.
		Logger logger = Logger.getLogger(nose.class.getName());
		BLogger blc = new BLogger();
		blc.config(logger);

        logger.info("doing stuff");
		System.out.println(nose.class.getName());

        logger.fine("done");
    }
}



