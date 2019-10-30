import { Component, OnInit } from "@angular/core";
import { FormArray } from "@angular/forms";
import { OcchabFormService } from "../services/form-service";
import { OcchabStoreService } from "../services/store.service";
import { OccHabDataService } from "../services/data.service";
import { leafletDrawOption } from "@geonature_common/map/leaflet-draw.options";
import { ActivatedRoute, Router } from "@angular/router";
import { Subscription } from "rxjs/Subscription";
import { CommonService } from "@geonature_common/service/common.service";
import { AppConfig } from "@geonature_config/app.config";

@Component({
  selector: "pnx-occhab-form",
  templateUrl: "occhab-form.component.html",
  styleUrls: ["./occhab-form.component.scss"],
  providers: [OcchabFormService]
})
export class OccHabFormComponent implements OnInit {
  public leafletDrawOptions = leafletDrawOption;
  public filteredHab: any;
  private _sub: Subscription;
  public editionMode = false;
  public MAP_SMALL_HEIGHT = "50vh";
  public MAP_FULL_HEIGHT = "87vh";
  public mapHeight = this.MAP_FULL_HEIGHT;
  public appConfig = AppConfig;
  public showHabForm = false;
  public showTabHab = false;
  public showDepth = false;

  constructor(
    public occHabForm: OcchabFormService,
    private _occHabDataService: OccHabDataService,
    public storeService: OcchabStoreService,
    private _route: ActivatedRoute,
    private _router: Router,
    private _commonService: CommonService
  ) {}

  ngOnInit() {
    this.leafletDrawOptions;
    leafletDrawOption.draw.polyline = false;
    this.occHabForm.stationForm = this.occHabForm.initStationForm();
  }

  ngAfterViewInit() {
    // get the id from the route
    this._sub = this._route.params.subscribe(params => {
      if (params["id_station"]) {
        this.editionMode = true;
        this.showHabForm = false;
        this.showTabHab = true;
        this._occHabDataService
          .getOneStation(params["id_station"])
          .subscribe(station => {
            this.occHabForm.patchStationForm(station);

            this.mapHeight = this.MAP_SMALL_HEIGHT;
          });
      }
    });
  }

  addNewHab() {
    this.occHabForm.addNewHab();
    this.showHabForm = true;
  }

  validateHabitat() {
    this.mapHeight = this.MAP_SMALL_HEIGHT;
    this.showHabForm = false;
    this.showTabHab = true;
    this.occHabForm.currentEditingHabForm = null;
  }

  // toggle the hab form and call the editHab function of form service
  editHab(index) {
    this.occHabForm.editHab(index);
    this.showHabForm = true;
  }

  cancelHab() {
    this.showHabForm = false;
    this.occHabForm.cancelHab();
  }

  toggleDepth() {
    this.showDepth = !this.showDepth;
  }

  postStation() {
    const station = this.occHabForm.formatStationBeforePost();
    this._occHabDataService.postStation(station).subscribe(
      data => {
        this.occHabForm.resetAllForm();
        this._router.navigate(["occhab"]);
      },
      error => {
        if (error.status === 403) {
          this._commonService.translateToaster("error", "NotAllowed");
        } else {
          this._commonService.translateToaster("error", "ErrorMessage");
        }
      }
    );
  }

  formatter(item) {
    return item.search_name;
  }

  ngOnDestroy() {
    this._sub.unsubscribe();
  }
}
