import java.util.logging.Handler;
import java.util.logging.LogRecord;

class errhandle extends Handler {

	public errhandle() {
		super();
	}


	public void publish(LogRecord logRecord) {
		System.out.println(logRecord.getLevel() + ":");
		System.out.println(logRecord.getSourceClassName() + ":");
		System.out.println(logRecord.getSourceMethodName() + ":");
		System.out.println("<" + logRecord.getMessage() + ">");
		System.out.println("\n");
	}

	public void flush() {}

	public void close() {}
}