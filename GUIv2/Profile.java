package pmpp;

import java.awt.BorderLayout;
import java.awt.FlowLayout;

import javax.swing.JButton;
import javax.swing.JDialog;
import javax.swing.JPanel;
import javax.swing.border.EmptyBorder;
import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;
import javax.swing.JLabel;
import javax.swing.SwingConstants;
import java.awt.Font;
import java.awt.GridBagLayout;
import java.awt.GridBagConstraints;
import java.awt.Insets;

@SuppressWarnings("serial")
public class Profile extends JDialog {

	private final JPanel contentPanel = new JPanel();

	/**
	 * Launch the application.
	 */
	public static void main(String[] args) {
		try {
			Profile dialog = new Profile();
			dialog.setDefaultCloseOperation(JDialog.DISPOSE_ON_CLOSE);
			dialog.setVisible(true);
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	/**
	 * Create the dialog.
	 */
	public Profile() {
		setBounds(100, 100, 450, 300);
		getContentPane().setLayout(new BorderLayout());
		contentPanel.setBorder(new EmptyBorder(5, 5, 5, 5));
		getContentPane().add(contentPanel, BorderLayout.CENTER);
		contentPanel.setLayout(new BorderLayout(0, 0));
		{
			JLabel lblMyProfile = new JLabel("My Profile");
			lblMyProfile.setFont(new Font("Courier New", Font.PLAIN, 30));
			lblMyProfile.setHorizontalAlignment(SwingConstants.CENTER);
			contentPanel.add(lblMyProfile, BorderLayout.NORTH);
		}
		{
			JPanel panel = new JPanel();
			contentPanel.add(panel, BorderLayout.CENTER);
			GridBagLayout gbl_panel = new GridBagLayout();
			gbl_panel.columnWidths = new int[]{0, 0};
			gbl_panel.rowHeights = new int[]{0, 0, 0, 0, 0, 0, 0};
			gbl_panel.columnWeights = new double[]{0.0, Double.MIN_VALUE};
			gbl_panel.rowWeights = new double[]{0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Double.MIN_VALUE};
			panel.setLayout(gbl_panel);
			{
				JLabel lblName = new JLabel("Username:");
				GridBagConstraints gbc_lblName = new GridBagConstraints();
				gbc_lblName.insets = new Insets(0, 0, 5, 0);
				gbc_lblName.gridx = 0;
				gbc_lblName.gridy = 0;
				panel.add(lblName, gbc_lblName);
			}
			{
				JLabel lblStatus = new JLabel("Status:");
				GridBagConstraints gbc_lblStatus = new GridBagConstraints();
				gbc_lblStatus.insets = new Insets(0, 0, 5, 0);
				gbc_lblStatus.gridx = 0;
				gbc_lblStatus.gridy = 1;
				panel.add(lblStatus, gbc_lblStatus);
			}
			{
				JLabel lblIpAddress = new JLabel("IP Address:");
				GridBagConstraints gbc_lblIpAddress = new GridBagConstraints();
				gbc_lblIpAddress.insets = new Insets(0, 0, 5, 0);
				gbc_lblIpAddress.gridx = 0;
				gbc_lblIpAddress.gridy = 2;
				panel.add(lblIpAddress, gbc_lblIpAddress);
			}
			{
				JLabel lblDisplayPicture = new JLabel("Display Picture:");
				GridBagConstraints gbc_lblDisplayPicture = new GridBagConstraints();
				gbc_lblDisplayPicture.insets = new Insets(0, 0, 5, 0);
				gbc_lblDisplayPicture.gridx = 0;
				gbc_lblDisplayPicture.gridy = 3;
				panel.add(lblDisplayPicture, gbc_lblDisplayPicture);
			}
		}
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
	}

}
