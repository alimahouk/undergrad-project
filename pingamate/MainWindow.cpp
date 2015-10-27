#include "MainWindow.h"

#include "Dwmapi.h"

using namespace System;
using namespace System::Windows::Forms;

[STAThread]
void Main(array<String^>^ args)
{
	Application::EnableVisualStyles();
	Application::SetCompatibleTextRenderingDefault(false);
	
	pingamate::MainWindow form;
	HWND hwnd = (HWND)form.Handle.ToPointer(); // Get a window handle in case we need it later.

	Application::Run(%form);
}