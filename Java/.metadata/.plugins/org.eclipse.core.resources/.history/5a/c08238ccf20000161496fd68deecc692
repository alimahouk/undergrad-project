package Demo_Chat;

import java.awt.BorderLayout;
import java.awt.FlowLayout;

import javax.swing.JButton;
import javax.swing.JDialog;
import javax.swing.JPanel;
import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;
import javax.swing.JLabel;
import javax.swing.SwingConstants;
import javax.swing.JTextArea;
import java.awt.Color;

@SuppressWarnings("serial")
public class About extends JDialog {

	/**
	 * Launch the application.
	 */
	public static void main(String[] args) {
		try {
			About dialog = new About();
			dialog.setDefaultCloseOperation(JDialog.DISPOSE_ON_CLOSE);
			dialog.setVisible(true);
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	/**
	 * Create the dialog.
	 */
	public About() {
		setBounds(100, 100, 450, 300);
		getContentPane().setLayout(new BorderLayout());
		{
			JPanel buttonPane = new JPanel();
			buttonPane.setLayout(new FlowLayout(FlowLayout.RIGHT));
			getContentPane().add(buttonPane, BorderLayout.SOUTH);
			{
				JButton okButton = new JButton("OK");
				okButton.addActionListener(new ActionListener() {
					public void actionPerformed(ActionEvent e) {
						dispose(); 
					}
				});
				okButton.setActionCommand("OK");
				buttonPane.add(okButton);
				getRootPane().setDefaultButton(okButton);
			}
		}
		{
			JLabel lblPingamateV = new JLabel("Pingamate v0.1");
			lblPingamateV.setHorizontalAlignment(SwingConstants.CENTER);
			getContentPane().add(lblPingamateV, BorderLayout.NORTH);
		}
		{
			JTextArea txtrCreatedBy = new JTextArea();
			txtrCreatedBy.setBackground(Color.WHITE);
			txtrCreatedBy.setText("Created By: \nAhmed Nor-Dine\nAli Mahouk \nIbrahim Mwinyi\nKaran Jhaveri \nVishal Ghaghada\n");
			getContentPane().add(txtrCreatedBy, BorderLayout.CENTER);
		}
	}

}
