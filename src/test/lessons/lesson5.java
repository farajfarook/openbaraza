import java.awt.*;
import java.awt.event.*;
import javax.swing.*;

public class lesson5 implements ActionListener {
	JPanel panel;
	JLabel l1, l2, l3, l4, l5;
	JTextField tf1, tf2, tf3;
	JButton b1, b2, b3, b4;

	public static void main(String args[]) {
		lesson5 ls5 = new lesson5();
		ls5.addComponents();
	}

	public void addComponents() {
		JFrame frame = new JFrame("Baraza Test");
		frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);

		panel = new JPanel(new GridLayout(6, 2));
		l1 = new JLabel("First Number : ");
		tf1 = new JTextField(25);
		panel.add(l1);
		panel.add(tf1);

		l2 = new JLabel("Second Number : ");
		tf2 = new JTextField(25);
		panel.add(l2);
		panel.add(tf2);

		l3 = new JLabel("Your Answer : ");
		tf3 = new JTextField(25);
		panel.add(l3);
		panel.add(tf3);

		b1 = new JButton("+");
		b2 = new JButton("-");
		b3 = new JButton("*");
		b4 = new JButton("/");
		panel.add(b1);
		panel.add(b2);
		panel.add(b3);
		panel.add(b4);
		b1.addActionListener(this);
		b2.addActionListener(this);
		b3.addActionListener(this);
		b4.addActionListener(this);

		l4 = new JLabel("");
		l5 = new JLabel("");
		panel.add(l4);
		panel.add(l5);

		frame.getContentPane().add(panel, BorderLayout.CENTER);
		frame.setSize(400,400);
		frame.setVisible(true);
	}

	public void actionPerformed(ActionEvent ev) { 
		String op = ev.getActionCommand();
		String n1 = tf1.getText();
		String n2 = tf2.getText();
		String n3 = tf3.getText();

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
			l4.setText("Enter the correct operator");
		}

		if(ans == true) {
			l4.setText("Correct answer");
		} else {
			l4.setText("Incorrect answer");
			l5.setText("The correct answer is : " + ca);
		}
	}


}