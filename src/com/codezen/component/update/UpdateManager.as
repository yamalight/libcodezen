package com.codezen.component.update
{
	import air.update.ApplicationUpdater;
	import air.update.events.DownloadErrorEvent;
	import air.update.events.StatusFileUpdateErrorEvent;
	import air.update.events.StatusFileUpdateEvent;
	import air.update.events.StatusUpdateErrorEvent;
	import air.update.events.StatusUpdateEvent;
	import air.update.events.UpdateEvent;
	
	import flash.desktop.NativeApplication;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.system.System;
	
	public class UpdateManager
	{
		private var appUpdater:ApplicationUpdater;
		private var appVersion:String;
		private var baseURL:String;
		private var updaterDialog:UpdateDialog;
		private var isFirstRun:String;
		private var upateVersion:String;
		private var applicationName:String;
		private var installedVersion:String;
		private var description:String;
		private var updateURL:String;
		
		private var initializeCheckNow:Boolean = false;
		private var isInstallPostponed:Boolean = false;
		private var showCheckState:Boolean = true;
		
		/**
		 * Constructer for UpdateManager Class
		 * 
		 * @param showCheckState Boolean value to show the Check Now dialog box
		 * @param initializeCheckNow Boolean value to initialize application and run check on instantiation of the Class
		 * */
		public function UpdateManager(updateURL:String, showCheckState:Boolean = true, initializeCheckNow:Boolean = false)
		{
			this.updateURL = updateURL;
			this.showCheckState = showCheckState;
			this.initializeCheckNow = initializeCheckNow;
			initialize();
		}
		
		public function checkNow():void
		{
			//trace("checkNow");
			isInstallPostponed = false;
			if(showCheckState) {
				createDialog(UpdateDialog.CHECK_UPDATE);
			} else {
				appUpdater.checkNow();
			}
		}
		
		public function get firstRun():Boolean{
			return isFirstRun == 'true';
		}
		
		//----------  ApplicationUpdater ----------------//
		
		private function initialize():void
		{
			//trace("initialize");
			if(!appUpdater){
				appUpdater = new ApplicationUpdater();
				appUpdater.updateURL = updateURL;
				appUpdater.addEventListener(UpdateEvent.INITIALIZED, updaterInitialized);
				appUpdater.addEventListener(StatusUpdateEvent.UPDATE_STATUS, statusUpdate);
				appUpdater.addEventListener(UpdateEvent.BEFORE_INSTALL, beforeInstall);
				appUpdater.addEventListener(StatusUpdateErrorEvent.UPDATE_ERROR, statusUpdateError);
				appUpdater.addEventListener(UpdateEvent.DOWNLOAD_START, downloadStarted);
				appUpdater.addEventListener(ProgressEvent.PROGRESS, downloadProgress);
				appUpdater.addEventListener(UpdateEvent.DOWNLOAD_COMPLETE, downloadComplete);
				appUpdater.addEventListener(DownloadErrorEvent.DOWNLOAD_ERROR, downloadError);
				appUpdater.addEventListener(ErrorEvent.ERROR, updaterError);
				appUpdater.initialize();
			}
		}
		
		private function beforeInstall(event:UpdateEvent):void
		{
			//trace("beforeInstall");
			if (isInstallPostponed) {
				event.preventDefault();
				isInstallPostponed = false;
			}
		}
		
		private function updaterInitialized(event:UpdateEvent):void
		{
			//trace("updaterInitialized");
			this.isFirstRun = event.target.isFirstRun;
			this.applicationName = getApplicationName();
			this.installedVersion = getApplicationVersion();
			
			if(showCheckState && initializeCheckNow) {
				createDialog(UpdateDialog.CHECK_UPDATE);
			} else if (initializeCheckNow) {
				appUpdater.checkNow();
			}
		}
		
		private function statusUpdate(event:StatusUpdateEvent):void
		{
			//trace("statusUpdate");
			event.preventDefault();
			if(event.available){
				this.description = getUpdateDescription(event.details);
				this.upateVersion = event.version;
				
				if(!showCheckState) {
					createDialog(UpdateDialog.UPDATE_AVAILABLE);
				} else if (updaterDialog) {
					updaterDialog.applicationName = this.applicationName;
					updaterDialog.installedVersion = this.installedVersion;
					updaterDialog.upateVersion = this.upateVersion;
					updaterDialog.description = this.description
					updaterDialog.updateState = UpdateDialog.UPDATE_AVAILABLE;
				}
			} else {
				//createDialog(UpdateDialog.NO_UPDATE);
				destroy();
			}
		}
		
		private function statusUpdateError(event:StatusUpdateErrorEvent):void
		{
			event.preventDefault();
			if(!updaterDialog){
				createDialog(UpdateDialog.UPDATE_ERROR);
			} else {
				updaterDialog.updateState = UpdateDialog.UPDATE_ERROR;
			}
		}
		
		private function statusFileUpdate(event:StatusFileUpdateEvent):void
		{
			event.preventDefault();
			if(event.available) {
				updaterDialog.updateState = UpdateDialog.UPDATE_DOWNLOADING;
				appUpdater.downloadUpdate();
			} else {
				updaterDialog.updateState = UpdateDialog.UPDATE_ERROR;
			}
		}
		
		private function statusFileUpdateError(event:StatusFileUpdateErrorEvent):void
		{
			event.preventDefault();
			updaterDialog.updateState = UpdateDialog.UPDATE_ERROR;;
		}
		
		private function downloadStarted(event:UpdateEvent):void
		{
			updaterDialog.updateState = UpdateDialog.UPDATE_DOWNLOADING;
		}
		
		private function downloadProgress(event:ProgressEvent):void
		{
			//UpdateDialog.updateState = UpdateDialog.UPDATE_DOWNLOADING;
			var num:Number = (event.bytesLoaded/event.bytesTotal)*100;
			updaterDialog.downloadProgress(num);
		}
		
		private function downloadComplete(event:UpdateEvent):void
		{
			event.preventDefault(); // prevent default install
			updaterDialog.updateState = UpdateDialog.INSTALL_UPDATE;
		}
		
		private function downloadError(event:DownloadErrorEvent):void
		{
			event.preventDefault();
			updaterDialog.updateState = UpdateDialog.UPDATE_ERROR;
		}
		
		private function updaterError(event:ErrorEvent):void
		{
			updaterDialog.errorText = event.text;
			updaterDialog.updateState = UpdateDialog.UPDATE_ERROR;
		}
		
		//----------  UpdateDialog Events ----------------//
		
		private function createDialog(state:String):void
		{
			if(!updaterDialog) {
				updaterDialog = new UpdateDialog();
				updaterDialog.isFirstRun = this.isFirstRun;
				updaterDialog.applicationName = this.applicationName;
				updaterDialog.installedVersion = this.installedVersion;
				updaterDialog.upateVersion = this.upateVersion;
				updaterDialog.updateState = state;
				updaterDialog.description = this.description;
				updaterDialog.addEventListener(UpdateDialog.EVENT_CHECK_UPDATE, checkUpdate);
				updaterDialog.addEventListener(UpdateDialog.EVENT_INSTALL_UPDATE, installUpdate);
				updaterDialog.addEventListener(UpdateDialog.EVENT_CANCEL_UPDATE, cancelUpdate);
				updaterDialog.addEventListener(UpdateDialog.EVENT_DOWNLOAD_UPDATE, downloadUpdate);
				updaterDialog.addEventListener(UpdateDialog.EVENT_INSTALL_LATER, installLater);
				updaterDialog.open();
			} 
		}
		
		/**
		 * Check for update.
		 * */
		private function checkUpdate(event:Event):void
		{
			//trace("checkUpdate");
			appUpdater.checkNow();
		}
		
		/**
		 * Install the update.
		 * */
		private function installUpdate(event:Event):void
		{
			appUpdater.installUpdate();
		}
		
		/**
		 * Install the update.
		 * */
		private function installLater(event:Event):void
		{
			isInstallPostponed = true;
			appUpdater.installUpdate();
			destoryUpdater();
		}
		
		/**
		 * Download the update.
		 * */
		private function downloadUpdate(event:Event):void
		{
			appUpdater.downloadUpdate();
		}
		
		/**
		 * Cancel the update.
		 * */
		private function cancelUpdate(event:Event):void
		{
			appUpdater.cancelUpdate();
			destoryUpdater();
		}
		
		//----------  Destroy All ----------------//
		
		private function destroy():void
		{
			if (appUpdater) {
				appUpdater.configurationFile = null;
				appUpdater.removeEventListener(UpdateEvent.INITIALIZED, updaterInitialized);
				appUpdater.removeEventListener(StatusUpdateEvent.UPDATE_STATUS, statusUpdate);
				appUpdater.removeEventListener(StatusUpdateErrorEvent.UPDATE_ERROR, statusUpdateError);
				appUpdater.removeEventListener(UpdateEvent.DOWNLOAD_START, downloadStarted);
				appUpdater.removeEventListener(ProgressEvent.PROGRESS, downloadProgress);
				appUpdater.removeEventListener(UpdateEvent.DOWNLOAD_COMPLETE, downloadComplete);
				appUpdater.removeEventListener(DownloadErrorEvent.DOWNLOAD_ERROR, downloadError);
				appUpdater.removeEventListener(UpdateEvent.BEFORE_INSTALL, beforeInstall);
				appUpdater.removeEventListener(ErrorEvent.ERROR, updaterError);
				
				
				appUpdater = null;
			}
			
			destoryUpdater();
		}
		
		private function destoryUpdater():void
		{
			if(updaterDialog) {
				updaterDialog.destroy();
				updaterDialog.removeEventListener(UpdateDialog.EVENT_CHECK_UPDATE, checkUpdate);
				updaterDialog.removeEventListener(UpdateDialog.EVENT_INSTALL_UPDATE, installUpdate);
				updaterDialog.removeEventListener(UpdateDialog.EVENT_CANCEL_UPDATE, cancelUpdate);
				updaterDialog.removeEventListener(UpdateDialog.EVENT_DOWNLOAD_UPDATE, downloadUpdate);
				updaterDialog.removeEventListener(UpdateDialog.EVENT_INSTALL_LATER, installLater);
				updaterDialog.close();
				updaterDialog = null;
			}
			isInstallPostponed = false;
			
			// force gc
			System.gc();
		}
		
		//----------  Utilities ----------------//
		
		/**
		 * Getter method to get the version of the application
		 * Based on Jens Krause blog post: http://www.websector.de/blog/2009/09/09/custom-applicationupdaterui-for-using-air-updater-framework-in-flex-4/
		 *
		 * @return String Version of application
		 *
		 */
		private function getApplicationVersion():String
		{
			var appXML:XML = NativeApplication.nativeApplication.applicationDescriptor;
			var ns:Namespace = appXML.namespace();
			return appXML.ns::version;
		}
		
		/**
		 * Getter method to get the name of the application file
		 * Based on Jens Krause blog post: http://www.websector.de/blog/2009/09/09/custom-applicationupdaterui-for-using-air-updater-framework-in-flex-4/
		 *
		 * @return String name of application
		 *
		 */
		private function getApplicationFileName():String
		{
			var appXML:XML = NativeApplication.nativeApplication.applicationDescriptor;
			var ns:Namespace = appXML.namespace();
			return appXML.ns::filename;
		}
		
		/**
		 * Getter method to get the name of the application, this does not support multi-language.
		 * Based on a method from Adobes ApplicationUpdateDialogs.mxml, which is part of Adobes AIR Updater Framework
		 * Also based on Jens Krause blog post: http://www.websector.de/blog/2009/09/09/custom-applicationupdaterui-for-using-air-updater-framework-in-flex-4/
		 *
		 * @return String name of application
		 *
		 */
		private function getApplicationName():String
		{
			var applicationName:String;
			var xmlNS:Namespace=new Namespace("http://www.w3.org/XML/1998/namespace");
			var appXML:XML=NativeApplication.nativeApplication.applicationDescriptor;
			var ns:Namespace=appXML.namespace();
			
			// filename is mandatory
			var elem:XMLList=appXML.ns::filename;
			
			// use name is if it exists in the application descriptor
			if ((appXML.ns::name).length() != 0)
			{
				elem=appXML.ns::name;
			}
			
			// See if element contains simple content
			if (elem.hasSimpleContent())
			{
				applicationName=elem.toString();
			}
			
			return applicationName;
		}
		
		/**
		 * Helper method to get release notes, this does not support multi-language.
		 * Based on a method from Adobes ApplicationUpdateDialogs.mxml, which is part of Adobes AIR Updater Framework
		 * Also based on Jens Krause blog post: http://www.websector.de/blog/2009/09/09/custom-applicationupdaterui-for-using-air-updater-framework-in-flex-4/
		 *
		 * @param detail Array of details
		 * @return String Release notes depending on locale chain
		 *
		 */
		private function getUpdateDescription(details:Array):String
		{
			var text:String="";
			
			if (details.length == 1)
			{
				text=details[0][1];
			}
			return text;
		}
	}
}