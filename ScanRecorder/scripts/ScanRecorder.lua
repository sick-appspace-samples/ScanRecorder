--[[----------------------------------------------------------------------------

  Application Name: ScanRecorder

  Description:
  Recording scan data from a scanner device to a file.

  Required: Scanner device

  This sample stores scans from a scanner device to a file in the
  local AppData folder. The application stores the scan only in a fix internal
  and by converting it before to a point cloud. Every scan is viewed on the webpage.
  Recording a set of scans in a real environment can be useful for development purposes.

  The IP address has to be adapted to match the actual device. The application can be
  stopped to stop the recording. In the private App folder "ScanRecorder" under
  "LastRecord" the current set of point clouds can be found. The maximum number of
  records is specified in the script.

------------------------------------------------------------------------------]]
--Start of Global Scope---------------------------------------------------------

-- luacheck: globals gViewer gTransformer gRemoteScanner gHandleNewScan

local RemoteScannerIP = '192.168.0.1' -- Adapt to match actual device

-- Configure and prepare the record folder
local maxNumberOfRecords = 50
local recordIntervalMs = 200
local lastRecordTime = DateTime.getTimestamp() -- intialize with current time
local recordFolder = 'private/LastRecord'
File.del(recordFolder)
File.mkdir(recordFolder)

-- Create a gViewer instance
gViewer = View.create()
gViewer:setID('viewer3D')

-- Create a transform instance to convert the Scan to a PointCloud
gTransformer = Scan.Transform.create()

-- Configure the scan device and start the scan
gRemoteScanner = Scan.Provider.RemoteScanner.create()
Scan.Provider.RemoteScanner.setIPAddress(gRemoteScanner, RemoteScannerIP)
Scan.Provider.RemoteScanner.register( gRemoteScanner, 'OnNewScan', 'gHandleNewScan' )
Scan.Provider.RemoteScanner.start(gRemoteScanner)

--End of Global Scope-----------------------------------------------------------

--Start of Function and Event Scope---------------------------------------------

-- Is called when a scan is received
function gHandleNewScan(scan, _)
  local ts = DateTime.getTimestamp()
  -- Transform to PointCloud to save and view the scan
  local pointCloud = Scan.Transform.transformToPointCloud(gTransformer, scan)

  -- Only record the scans every defined interval
  -- The saving of the pointcloud needs some time, so cannot record every scan here
  -- Other possibility would be to collect more scans together in one single PointCloud
  if (ts > recordIntervalMs) and (ts - lastRecordTime > recordIntervalMs) then
    lastRecordTime = ts

    -- Create name for the output file and store pointCloud
    local fileName = recordFolder .. '/record_' .. ts .. '.ssr'
    PointCloud.save(pointCloud, fileName)
    print("Recorded new PointCloud file '" .. fileName .. "'")

    -- Delete oldest file if there are more
    local recordList = File.list(recordFolder)
    if (#recordList > maxNumberOfRecords) then
      -- Records are sorted because of the encapsulated timestamp. Therefore delete the first (oldest) one
      File.del(recordFolder .. '/' .. recordList[1])
    end
  end

  -- present every pointcloud in the gViewer
  View.view(gViewer, pointCloud)
end

--End of Function and Event Scope------------------------------------------------
