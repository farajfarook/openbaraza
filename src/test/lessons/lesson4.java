import java.io.Console;

public class lesson4 {

	public static void main(String arg[]) {
		System.out.println("Welcome to the testing program.");

		Console c = System.console();
		String n1 = c.readLine("Enter a number : ");
		String op = c.readLine("Choose [+ - *] : ");
		String n2 = c.readLine("Enter the other number : ");
		String n3 = c.readLine("Enter the answer : ");
		
		lesson3 ls3 = new lesson3();
		int ca = 0;
		boolean ans = false;
		if(op.equals("+")) {
			ca = ls3.add(n1, n2);
			ans = ls3.check(n3);
		} else if(op.equals("-")) {
			ca = ls3.sub(n1, n2);
			ans = ls3.check(n3);
		} else if(op.equals("*")) {
			ca = ls3.multiply(n1, n2);
			ans = ls3.check(n3);
		} else {
			System.out.println("Enter the correct operator");
		}

		if(ans == true) {
			System.out.println("Correct answer");
		} else {
			 System.out.println("Incorrect answer, the correct answer is : " + ca);
		}

	}

}
