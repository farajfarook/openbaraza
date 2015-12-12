import java.util.logging.Logger;
import java.util.logging.FileHandler;
import java.util.logging.Level;
import java.util.logging.SimpleFormatter;

class BLogger {

	public void config(Logger logger) {
		logger.addHandler(new errhandle());
		try {
			FileHandler fh = new FileHandler("/root/baraza/src/test/logs/wombat.log", 1048576, 5, true);
			fh.setFormatter(new SimpleFormatter());
			logger.addHandler(fh);
		} catch(java.io.IOException ex) {}
		logger.setUseParentHandlers(false);
		logger.setLevel(Level.FINEST);
	}

}
